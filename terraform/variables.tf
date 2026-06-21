# Переменные Terraform
variable "yc_cloud_id" { type = string }
variable "yc_folder_id" { type = string }
variable "yc_zones" { type = list(string), default = ["ru-central1-a", "ru-central1-b"] }
variable "service_account_key_file" { type = string, default = "~/diplom-sa-key.json" }
variable "project_name" { type = string, default = "diplom-project" }
variable "ssh_public_key_path" { type = string, default = "~/.ssh/diplom.pub" }
variable "ssh_private_key_path" { type = string, default = "~/.ssh/diplom" }
