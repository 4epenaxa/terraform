# Get the latest Ubuntu image
data "sbercloud_images_image" "ubuntu_image" {
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
}
# --- SSH-ключ ---
resource "sbercloud_compute_keypair" "key_ex1" {
  name       = "tf_key"
  public_key = file("~/.ssh/id_rsa.pub")  # путь к вашему .pub файлу
}
# --- Сеть ---
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


# Create ECS
resource "sbercloud_compute_instance" "ecs_01" {
  count             = var.vm_count
  name              = "VM-${count.index + 1}"
  
  image_id          = data.sbercloud_images_image.ubuntu_image.id
  flavor_id         = "s7n.medium.2"
  security_groups   = ["Sys-WebServer"]
  availability_zone = "ru-moscow-1a"
#   key_pair          = count.index == 0 ? sbercloud_compute_keypair.key_ex1.name : null
#   admin_pass        = count.index == 0 ? null : var.root_password
  key_pair          = sbercloud_compute_keypair.key_ex1.name
#   admin_pass        = var.root_password

  system_disk_type = "SAS"
  system_disk_size = 16

  network {
    uuid = count.index == 0 ? sbercloud_vpc_subnet.subnet_01.id : sbercloud_vpc_subnet.subnet_02.id
  }
}

# Create EIP for NAT Gateway
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

# Create NAT Gateway
resource "sbercloud_nat_gateway" "nat_01" {
  name        = "nat-terraform"
  description = "Demo NAT Gateway"
  spec        = "1"
  vpc_id      = sbercloud_vpc.vpc_01.id
  subnet_id   = sbercloud_vpc_subnet.subnet_01.id
}

# Create SNAT rule for your subnet
resource "sbercloud_nat_snat_rule" "snat_only_vm1" {
  nat_gateway_id = sbercloud_nat_gateway.nat_01.id
  subnet_id      = sbercloud_vpc_subnet.subnet_01.id
  floating_ip_id = sbercloud_vpc_eip.nat_eip.id
}

resource "sbercloud_nat_dnat_rule" "ssh_dnat_vm1" {
  nat_gateway_id = sbercloud_nat_gateway.nat_01.id
  floating_ip_id = sbercloud_vpc_eip.nat_eip.id

  # Порт VM-1, на который NAT будет перенаправлять
  port_id = sbercloud_compute_instance.ecs_01[0].network[0].port

  protocol              = "tcp"
  internal_service_port = 22
  external_service_port = 22
}

output "nat_eip_address" {
  description = "Public IP of NAT Gateway for SSH access"
  value       = sbercloud_vpc_eip.nat_eip.address
}
output "vm1_ssh_ip" {
  description = "Public IP to SSH into VM-1 via NAT Gateway"
  value       = sbercloud_vpc_eip.nat_eip.address
}
