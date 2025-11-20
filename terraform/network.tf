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