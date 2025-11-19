provider "sbercloud" {
    auth_url = "https://iam.ru-moscow-1.hc.sbercloud.ru/v.3"
    region   = "ru-moscow-1"

    access_key   = var.access_key
    secret_key   = var.secret_key
}