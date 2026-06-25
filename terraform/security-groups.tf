# Группы безопасности

# Bastion: доступ из интернета
resource "yandex_vpc_security_group" "bastion" {
  depends_on  = [time_sleep.wait_for_security_groups]
  name        = "${var.project_name}-bastion-sg"
  description = "Security group для bastion host"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description    = "SSH доступ"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "HTTP (сайт)"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Grafana"
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Kibana"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "Разрешаем весь исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Внутренняя группа: доступ от Bastion и между собой
resource "yandex_vpc_security_group" "internal" {
  depends_on  = [time_sleep.wait_for_security_groups]
  name        = "${var.project_name}-internal-sg"
  description = "Internal security group for all VMs"
  network_id  = yandex_vpc_network.main.id

  # Весь трафик от Bastion разрешён
  ingress {
    description       = "All traffic from Bastion"
    protocol          = "ANY"
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  # SSH от Bastion
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  # Разрешаем Elasticsearch (порт 9200) от других ВМ в группе
  ingress {
    description    = "Allow Elasticsearch from internal"
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/8"] # Разрешаем всю внутреннюю сеть
  }

  # Добавляем правило для Prometheus (порт 9090)
  ingress {
    description    = "Allow Prometheus from internal"
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = ["10.0.0.0/8"]   # разрешаем всей приватной сети
  }

  egress {
    description    = "Разрешаем весь исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Веб-серверы: доступ от Bastion и Prometheus
resource "yandex_vpc_security_group" "web" {
  depends_on  = [time_sleep.wait_for_security_groups]
  name        = "${var.project_name}-web-sg"
  description = "Security group для веб-серверов"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description       = "HTTP from Bastion"
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.bastion.id
  }
  ingress {
    description       = "SSH from Bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description    = "Node Exporter from Prometheus"
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.0.1.0/24"]
  }
  ingress {
    description    = "Nginx Exporter from Prometheus"
    protocol       = "TCP"
    port           = 9113
    v4_cidr_blocks = ["10.0.1.0/24"]
  }
  # НОВОЕ ПРАВИЛО для порта 4040
  ingress {
    description    = "Nginx Log Exporter from Prometheus"
    protocol       = "TCP"
    port           = 4040
    v4_cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    description    = "Разрешаем весь исходящий трафик"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}