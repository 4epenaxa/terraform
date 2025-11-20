output "nat_eip_address" {
  description = "Public IP of NAT Gateway for SSH access"
  value       = sbercloud_vpc_eip.nat_eip.address
}
output "vm1_ssh_ip" {
  description = "Public IP to SSH into VM-1 via NAT Gateway"
  value       = sbercloud_vpc_eip.nat_eip.address
}