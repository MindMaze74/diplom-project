# Результат и Генерация инвентаря для Ansible

output "bastion_public_ip" {
  description = "Публичный IP Bastion"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "web_private_ips" {
  description = "Приватные IP веб-серверов"
  value       = [for inst in yandex_compute_instance.web : inst.network_interface[0].ip_address]
}

output "prometheus_private_ip" {
  description = "Приватный IP Prometheus"
  value       = yandex_compute_instance.prometheus.network_interface[0].ip_address
}

output "grafana_private_ip" {
  description = "Приватный IP Grafana"
  value       = yandex_compute_instance.grafana.network_interface[0].ip_address
}

output "elasticsearch_private_ip" {
  description = "Приватный IP Elasticsearch"
  value       = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
}

output "kibana_private_ip" {
  description = "Приватный IP Kibana"
  value       = yandex_compute_instance.kibana.network_interface[0].ip_address
}

# Генерация инвентаря для Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    bastion_public_ip        = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
    web1_private_ip          = yandex_compute_instance.web[0].network_interface[0].ip_address
    web2_private_ip          = yandex_compute_instance.web[1].network_interface[0].ip_address
    prometheus_private_ip    = yandex_compute_instance.prometheus.network_interface[0].ip_address
    grafana_private_ip       = yandex_compute_instance.grafana.network_interface[0].ip_address
    elasticsearch_private_ip = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
    kibana_private_ip        = yandex_compute_instance.kibana.network_interface[0].ip_address
  })
  filename = "../ansible/inventory/inventory.ini"
}

output "alb_external_ip" {
  value = yandex_alb_load_balancer.web_lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
  description = "Public IP of Application Load Balancer"
}
