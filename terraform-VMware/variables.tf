variable "vcd_storage_policy" {}
variable "ova" {}
variable "edge_name" {}
variable "vcd_url" {} 
variable "org_name" {}
variable "org_vdc" {}
variable "vcd_max_retry_timeout" {
    default = "1680"
}
variable "vcd_allow_unverified_ssl" {
    default = "true"
}
variable "server_web_ip" {
default = "172.16.100.1"
}
variable "gateway_web_ip" {
default = "172.16.100.254"
}