# Получение существующего сервисного аккаунта
data "yandex_iam_service_account" "existing_sa" {
  name = "diplom-sa"
}

# Генерация статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "backup_sa_key" {
  service_account_id = data.yandex_iam_service_account.existing_sa.id
  description        = "Static access key for backup"
}

# Создание бакета и назначение роли через local-exec (yc CLI)
resource "null_resource" "setup_bucket" {
  depends_on = [
    yandex_iam_service_account_static_access_key.backup_sa_key
  ]

  triggers = {
    bucket_name = "${var.project_name}-backup-${var.yc_folder_id}"
    sa_id       = data.yandex_iam_service_account.existing_sa.id
  }

  provisioner "local-exec" {
    command = <<EOF
      # Проверяем, существует ли бакет
      BUCKET_EXISTS=$(yc storage bucket list --format json --cloud-id ${var.yc_cloud_id} | grep -o '"name": "${var.project_name}-backup-${var.yc_folder_id}"' || true)
      if [ -z "$BUCKET_EXISTS" ]; then
        echo "Creating bucket..."
        yc storage bucket create \
          --name ${var.project_name}-backup-${var.yc_folder_id} \
          --acl private \
          --folder-id ${var.yc_folder_id} \
          --cloud-id ${var.yc_cloud_id}
      else
        echo "Bucket already exists"
      fi

      # Назначаем роль storage.editor, если её нет
      if ! yc resource-manager folder list-access-bindings ${var.yc_folder_id} --format json | grep -q '"serviceAccountId": "${data.yandex_iam_service_account.existing_sa.id}"'; then
        echo "Assigning storage.editor role..."
        yc resource-manager folder add-access-binding ${var.yc_folder_id} \
          --role storage.editor \
          --service-account-id ${data.yandex_iam_service_account.existing_sa.id}
      else
        echo "Role already assigned"
      fi

      # Устанавливаем правило жизненного цикла (7 дней), используя правильный JSON
      echo "Setting lifecycle rule (7 days retention)..."
      yc storage bucket update \
        --name ${var.project_name}-backup-${var.yc_folder_id} \
        --lifecycle-rules '{"lifecycle_rules":[{"id":"cleanup","enabled":true,"expiration":{"days":7}}]}'
    EOF
  }
}

# Вывод sensitive данных для Ansible
output "backup_access_key" {
  value     = yandex_iam_service_account_static_access_key.backup_sa_key.access_key
  sensitive = true
}

output "backup_secret_key" {
  value     = yandex_iam_service_account_static_access_key.backup_sa_key.secret_key
  sensitive = true
}
