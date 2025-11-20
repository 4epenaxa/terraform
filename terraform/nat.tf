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