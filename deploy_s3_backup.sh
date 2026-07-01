#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Exporting backup keys from Terraform..."
export BACKUP_ACCESS_KEY=$(terraform -chdir=terraform output -raw backup_access_key)
export BACKUP_SECRET_KEY=$(terraform -chdir=terraform output -raw backup_secret_key)

echo "Running Ansible playbook for S3 backup setup..."
cd ansible
ansible-playbook -i inventory/inventory.ini playbooks/setup_s3_backup.yml
