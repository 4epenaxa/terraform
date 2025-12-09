terraform {
    required_providers {
        vcd = {
            source = "tf.repo.sbc.space/vmware/vcd"
            version = ">=3.10.0"
        }
    }
    required_version = ">=1.5.5"
}

# provider
provider "vcd" {
    user = "none"
    password = "none"
    auth_type = "api_token_file"
    api_token_file = "token.json"
    allow_api_token_file = true
    org = var.org_name
    vdc = var.org_vdc
    url = var.vcd_url
    max_retry_timeout = var.vcd_max_retry_timeout
    allow_unverified_ssl = var.vcd_allow_unverified_ssl
}