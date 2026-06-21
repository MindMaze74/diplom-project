# Inventory для Ansible

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
elasticsearch_private_ip=${elasticsearch_private_ip}

[bastion]
bastion ansible_host=${bastion_public_ip}

[bastion:vars]
web1_private_ip=${web1_private_ip}
web2_private_ip=${web2_private_ip}
grafana_private_ip=${grafana_private_ip}
kibana_private_ip=${kibana_private_ip}
elasticsearch_private_ip=${elasticsearch_private_ip}
prometheus_private_ip=${prometheus_private_ip}

[web:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${bastion_public_ip} -o StrictHostKeyChecking=no'
elasticsearch_private_ip=${elasticsearch_private_ip}

[web]
web1 ansible_host=${web1_private_ip}
web2 ansible_host=${web2_private_ip}

[prometheus:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${bastion_public_ip} -o StrictHostKeyChecking=no'

[prometheus]
prometheus ansible_host=${prometheus_private_ip}

[grafana:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${bastion_public_ip} -o StrictHostKeyChecking=no'

[grafana]
grafana ansible_host=${grafana_private_ip}

[elasticsearch:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${bastion_public_ip} -o StrictHostKeyChecking=no'
elasticsearch_private_ip=${elasticsearch_private_ip}

[elasticsearch]
elasticsearch ansible_host=${elasticsearch_private_ip}

[kibana:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${bastion_public_ip} -o StrictHostKeyChecking=no'

[kibana]
kibana ansible_host=${kibana_private_ip}
