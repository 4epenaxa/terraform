# --- Сеть ---
resource "sbercloud_vpc" "vpc_ex1" {
  name = "tf_vpc_1"
  cidr = "192.168.0.0/24"
}

resource "sbercloud_vpc_subnet" "subnet_ex1" {
  name       = "tf_subnet_1"
  cidr       = "192.168.0.0/25"
  gateway_ip = "192.168.0.1"
  vpc_id     = sbercloud_vpc.vpc_ex1.id
}

# --- Публичный IP ---
resource "sbercloud_vpc_eip" "eip_ex1" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "tf_bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# --- SSH-ключ ---
resource "sbercloud_compute_keypair" "key_ex1" {
  name       = "tf_key"
  public_key = file("~/.ssh/id_rsa.pub")  # путь к вашему .pub файлу
}

# --- Получаем образ и flavor ---
data "sbercloud_images_image" "image_ex1" {
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
}

data "sbercloud_compute_flavors" "vmtype" {
  availability_zone = "ru-moscow-1a"
  performance_type  = "normal"
  cpu_core_count    = 2
  memory_size       = 4
}

# --- Виртуальная машина ---
resource "sbercloud_compute_instance" "instance_ex1" {
  name              = "tf_instance"
  image_id          = data.sbercloud_images_image.image_ex1.id
  flavor_id         = data.sbercloud_compute_flavors.vmtype.ids[0]
  key_pair          = sbercloud_compute_keypair.key_ex1.name
  security_groups   = ["default"]
  availability_zone = "ru-moscow-1a"

  system_disk_type = "SAS"
  system_disk_size = 20

  network {
    uuid = sbercloud_vpc_subnet.subnet_ex1.id
  }
}

# --- Ассоциация публичного IP ---
resource "sbercloud_compute_eip_associate" "fip_assoc_ex1" {
  public_ip = sbercloud_vpc_eip.eip_ex1.address
  instance_id = sbercloud_compute_instance.instance_ex1.id
}

# --- Output ---
output "public_ip" {
  description = "Public IP of the VM"
  value       = sbercloud_vpc_eip.eip_ex1.address
}
