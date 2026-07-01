# Провайдеры Terraform
terraform {
  required_providers {
    yandex = { source = "yandex-cloud/yandex", version = "~> 0.95.0" }
    time   = { source = "hashicorp/time", version = "~> 0.9.0" }
    local  = { source = "hashicorp/local", version = "~> 2.4.0" }
    null   = { source = "hashicorp/null", version = "~> 3.2.0" }
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.yc_zones[0]
}
