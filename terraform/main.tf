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

# Create ECS
resource "sbercloud_compute_instance" "ecs_01" {
  count             = var.vm_count
  name              = "VM-${count.index + 1}"
  
  image_id          = data.sbercloud_images_image.ubuntu_image.id
  flavor_id         = "s7n.medium.2"
  security_groups   = [sbercloud_networking_secgroup.openNAT.name]
  availability_zone = "ru-moscow-1a"
  key_pair          = sbercloud_compute_keypair.key_ex1.name

  system_disk_type = "SAS"
  system_disk_size = 16

  network {
    uuid = sbercloud_vpc_subnet.subnet_01.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y nginx
    echo "Hello from VM-${count.index + 1}" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOF
}

# resource "sbercloud_compute_instance" "vm1" {
#   name              = "VM-1"
#   image_id          = data.sbercloud_images_image.ubuntu_image.id
#   flavor_id         = "s7n.medium.2"
#   security_groups   = [sbercloud_networking_secgroup.openNAT.name]
#   availability_zone = "ru-moscow-1a"
#   key_pair          = sbercloud_compute_keypair.key_ex1.name

#   system_disk_type = "SAS"
#   system_disk_size = 16

#   network {
#     uuid = sbercloud_vpc_subnet.subnet_01.id
#   }

#   user_data = <<-EOF
#     #!/bin/bash
#     apt update
#     apt install -y nginx
#     echo "Hello from VM-1" > /var/www/html/index.html
#     systemctl enable nginx
#     systemctl restart nginx
#   EOF
# }

# resource "sbercloud_compute_instance" "vm2" {
#   name              = "VM-2"
#   image_id          = data.sbercloud_images_image.ubuntu_image.id
#   flavor_id         = "s7n.medium.2"
#   security_groups   = [sbercloud_networking_secgroup.openNAT.name]
#   availability_zone = "ru-moscow-1a"
#   key_pair          = sbercloud_compute_keypair.key_ex1.name

#   system_disk_type = "SAS"
#   system_disk_size = 16

#   network {
#     uuid = sbercloud_vpc_subnet.subnet_01.id
#   }

#   user_data = <<-EOF
#     #!/bin/bash
#     apt update
#     apt install -y nginx
#     echo "Hello from VM-2" > /var/www/html/index.html
#     systemctl enable nginx
#     systemctl restart nginx
#   EOF
# }


