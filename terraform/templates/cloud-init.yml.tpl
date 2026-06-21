#cloud-config
#cloud-init для всех ВМ (кроме бастиона)
# 1. Создание пользователя ubuntu
# 2. Добавление SSH-ключа для доступа
# 3. Автоматическое обновление пакетов

users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${ssh_public_key}

package_update: true
package_upgrade: true
