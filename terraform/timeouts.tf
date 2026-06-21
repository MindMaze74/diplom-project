# Задержки для упорядоченного создания ресурсов

# Задержка перед созданием Security Groups
resource "time_sleep" "wait_for_security_groups" {
  create_duration = "60s"
  depends_on = [
    yandex_vpc_network.main,
    yandex_vpc_subnet.public,
    yandex_vpc_subnet.private
  ]
}

# Задержка перед созданием Bastion
resource "time_sleep" "wait_before_bastion" {
  create_duration = "90s" # Увеличено для гарантии
  depends_on = [
    yandex_vpc_subnet.public[0],
    yandex_vpc_security_group.bastion
  ]
}

# Задержка перед созданием остальных ВМ
resource "time_sleep" "wait_for_instances" {
  depends_on = [
    yandex_vpc_subnet.private[0],
    yandex_vpc_security_group.internal,
    yandex_vpc_security_group.web
  ]
  create_duration = "30s"
}

# Дополнительная задержка перед Bastion
resource "time_sleep" "wait_after_instances" {
  depends_on = [
    yandex_compute_instance.web[0],
    yandex_compute_instance.web[1],
    yandex_compute_instance.prometheus,
    yandex_compute_instance.grafana,
    yandex_compute_instance.elasticsearch,
    yandex_compute_instance.kibana
  ]
  create_duration = "60s"
}
