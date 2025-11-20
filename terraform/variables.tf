variable "access_key" {
    description = "Access Key to access SberCloud"
    sensitive   = true
}

variable "secret_key" {
    description = "Secret Key to access SberCloud"
    sensitive   = true
}

variable "root_password" {
  description = "Root password for ECS"
  sensitive   = true
}

variable "vm_count" {
  default = 2
}
