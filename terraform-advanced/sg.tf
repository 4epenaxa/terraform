resource "sbercloud_networking_secgroup" "openNAT" {
  name        = "openNAT"
  description = "Security group with full outbound Internet access"
}

resource "sbercloud_networking_secgroup_rule" "openNAT_ingress_ssh" {
  security_group_id = sbercloud_networking_secgroup.openNAT.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "sbercloud_networking_secgroup_rule" "openNAT_ingress_http" {
  security_group_id = sbercloud_networking_secgroup.openNAT.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

# Полностью открытый исходящий
resource "sbercloud_networking_secgroup_rule" "openNAT_egress_all" {
  security_group_id = sbercloud_networking_secgroup.openNAT.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "sbercloud_networking_secgroup" "closeNAT" {
  name        = "closeNAT"
  description = "Security group without Internet access"
  delete_default_rules = true
}

# Разрешаем вход с LB по HTTP (80)
resource "sbercloud_networking_secgroup_rule" "closeNAT_ingress_http" {
  security_group_id = sbercloud_networking_secgroup.closeNAT.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"  
  # Можно позже заменить на VIP ELB, если хочешь
}

resource "sbercloud_networking_secgroup_rule" "closeNAT_ingress_ssh" {
  security_group_id = sbercloud_networking_secgroup.closeNAT.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "sbercloud_networking_secgroup_rule" "closeNAT_ingress_all" {
  security_group_id = sbercloud_networking_secgroup.closeNAT.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
}
