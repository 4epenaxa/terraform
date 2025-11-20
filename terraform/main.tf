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
  name       = "subnet_terraform"
  cidr       = "192.168.0.0/25"
  gateway_ip = "192.168.0.1"
  vpc_id     = sbercloud_vpc.vpc_01.id
}

# Create ECS
resource "sbercloud_compute_instance" "ecs_01" {
  count             = var.vm_count
  name              = "VM-${count.index + 1}"
  
  image_id          = data.sbercloud_images_image.ubuntu_image.id
  flavor_id         = "s7n.medium.2"
  security_groups   = ["default"]
  availability_zone = "ru-moscow-1a"
  key_pair          = sbercloud_compute_keypair.key_ex1.name
  admin_pass        = var.root_password

  system_disk_type = "SAS"
  system_disk_size = 16

  network {
    uuid = sbercloud_vpc_subnet.subnet_01.id
  }
}