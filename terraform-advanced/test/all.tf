provider "sbercloud" {
    auth_url    = "https://iam.ru-moscow-1.hc.sbercloud.ru/v.3"
    region      = "ru-moscow-1"
    access_key  = var.access_key
    secret_key  = var.secret_key
}

terraform {
    required_version = "1.13.5"
    required_providers {
        sbercloud = {
            source  = "sbercloud-terraform/sbercloud"
            version = "1.12.14"
        }
    }
}

variable "access_key" {
    description = "Access Key to access SberCloud"
    sensitive   = true
}

variable "secret_key" {
    description = "Secret Key to access SberCloud"
    sensitive   = true
}

variable "root_password" {
  description = "Root password for ECS"
  sensitive   = true
}

variable "vm_count" {
  default = 2
}

data "sbercloud_images_image" "ubuntu_image" {
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
}

resource "sbercloud_vpc" "vpc_01" {
  name = "vpc_terraform"
  cidr = "192.168.0.0/24"
}

resource "sbercloud_vpc_subnet" "subnet_01" {
  name       = "subnet_internet_on"
  cidr       = "192.168.0.0/25"
  gateway_ip = "192.168.0.1"
  vpc_id     = sbercloud_vpc.vpc_01.id
}

resource "sbercloud_vpc_subnet" "subnet_02" {
  name       = "subnet_internet_off"
  cidr       = "192.168.0.128/25"
  gateway_ip = "192.168.0.129"
  vpc_id     = sbercloud_vpc.vpc_01.id
}

resource "sbercloud_vpc_eip" "nat_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "nat_bandwidth"
    size        = 1
    share_type  = "PER"
    charge_mode = "bandwidth"
  }
}

resource "sbercloud_nat_gateway" "nat_01" {
  name        = "nat-terraform"
  description = "Demo NAT Gateway"
  spec        = "1"
  vpc_id      = sbercloud_vpc.vpc_01.id
  subnet_id   = sbercloud_vpc_subnet.subnet_01.id
}

resource "sbercloud_nat_snat_rule" "snat_only_vm1" {
  nat_gateway_id = sbercloud_nat_gateway.nat_01.id
  subnet_id      = sbercloud_vpc_subnet.subnet_01.id
  floating_ip_id = sbercloud_vpc_eip.nat_eip.id
}

# DNAT access to VM1-ssh
resource "sbercloud_nat_dnat_rule" "ssh_dnat_vm1" {
  nat_gateway_id = sbercloud_nat_gateway.nat_01.id
  floating_ip_id = sbercloud_vpc_eip.nat_eip.id

  # Порт VM-1, на который NAT будет перенаправлять
  port_id = sbercloud_compute_instance.ecs_01[0].network[0].port

  protocol              = "tcp"
  internal_service_port = 22
  external_service_port = 22
}

resource "sbercloud_compute_keypair" "key_ex1" {
  name       = "tf_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "sbercloud_compute_instance" "ecs_01" {
  count             = var.vm_count
  name              = "VM-${count.index + 1}"
  
  image_id          = data.sbercloud_images_image.ubuntu_image.id
  flavor_id         = "s7n.medium.2"
  security_groups   = ["Sys-WebServer"]
  availability_zone = "ru-moscow-1a"
  key_pair          = sbercloud_compute_keypair.key_ex1.name

  system_disk_type = "SAS"
  system_disk_size = 16

  network {
    uuid = count.index == 0 ? sbercloud_vpc_subnet.subnet_01.id : sbercloud_vpc_subnet.subnet_02.id
  }

  # Cloud-init to install Nginx + custom index.html
  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y nginx
    echo "Hello from VM-${count.index + 1}" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOF
}

# resource "sbercloud_lb_loadbalancer" "elb_1" {
#   name          = var.loadbalancer_name
#   vip_subnet_id = sbercloud_vpc_subnet.subnet_01.subnet_id
# }

# ###############################################
# # HTTP Listener on port 80
# ###############################################
# resource "sbercloud_lb_listener" "listener_1" {
#   name            = "listener_http"
#   protocol        = "HTTP"
#   protocol_port   = 80
#   loadbalancer_id = sbercloud_lb_loadbalancer.elb_1.id
# }

# ###############################################
# # Backend Pool
# ###############################################
# resource "sbercloud_lb_pool" "group_1" {
#   name        = "group_1"
#   protocol    = "HTTP"
#   lb_method   = "ROUND_ROBIN"
#   listener_id = sbercloud_lb_listener.listener_1.id
# }

# ###############################################
# # Backend Members: VM1 + VM2
# ###############################################
# resource "sbercloud_elb_member" "member_vm1" {
#   pool_id       = sbercloud_lb_pool.group_1.id
#   address       = sbercloud_compute_instance.ecs_01[0].access_ip_v4
#   protocol_port = 80
#   subnet_id     = sbercloud_vpc_subnet.subnet_01.subnet_id
# }

# resource "sbercloud_elb_member" "member_vm2" {
#   pool_id       = sbercloud_lb_pool.group_1.id
#   address       = sbercloud_compute_instance.ecs_01[1].access_ip_v4
#   protocol_port = 80
#   subnet_id     = sbercloud_vpc_subnet.subnet_02.subnet_id
# }

# resource "sbercloud_lb_monitor" "health_check" {
#   name           = "health_check"
#   type           = "HTTP"
#   url_path       = "/"
#   expected_codes = "200-202"
#   delay          = 10
#   timeout        = 5
#   max_retries    = 3
#   pool_id        = sbercloud_lb_pool.group_1.id
# }

output "nat_eip_address" {
  description = "Public IP of NAT Gateway for SSH access"
  value       = sbercloud_vpc_eip.nat_eip.address
}

# output "load_balancer_address" {
#   description = "Public IP of Load Balancer"
#   value       = sbercloud_lb_loadbalancer.elb_1.vip_address
# }

output "vm1_ssh_ip" {
  description = "Public IP to SSH into VM-1 via NAT Gateway"
  value       = sbercloud_vpc_eip.nat_eip.address
}
