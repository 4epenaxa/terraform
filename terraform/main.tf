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
