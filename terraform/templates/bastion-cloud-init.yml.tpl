#cloud-config
#cloud-init для бастиона

# Bastion - единственная ВМ с публичным IP
# Выполняет роль:
# 1. SSH-шлюза
# 2. Прокси для сайта (порт 80)
# 3. Прокси для Grafana (порт 3000)
# 4. Прокси для Kibana (порт 5601)


users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${ssh_public_key}

packages:
  - nginx

write_files:
  - path: /etc/nginx/sites-available/default
    content: |
      # Балансировка на веб-серверы
      upstream web_backend {
          server ${web_private_ips[0]}:80;
          server ${web_private_ips[1]}:80;
      }

      # Сайт (порт 80)
      server {
          listen 80 default_server;
          server_name _;

          access_log /var/log/nginx/access.log combined;
          error_log /var/log/nginx/error.log warn;

          location / {
              proxy_pass http://web_backend;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          }
      }

      # Прокси для Grafana (порт 3000)
      server {
          listen 3000;
          server_name _;

          location / {
              proxy_pass http://${grafana_private_ip}:3000;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          }
      }

      # Прокси для Kibana (порт 5601)
      server {
          listen 5601;
          server_name _;

          location / {
              proxy_pass http://${kibana_private_ip}:5601;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          }
      }

runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
