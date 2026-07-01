# Security Group для Bastion
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description = "SSH from my IP"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["77.222.115.109/32"]
  }

  ingress {
    description = "Grafana"
    protocol    = "TCP"
    port        = 3000
    v4_cidr_blocks = ["77.222.115.109/32"]
  }

  ingress {
    description = "Kibana"
    protocol    = "TCP"
    port        = 5601
    v4_cidr_blocks = ["77.222.115.109/32"]
  }

  egress {
    description = "Allow all outgoing"
    protocol    = "ANY"
    port        = -1
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Общая Security Group для внутренних ВМ
resource "yandex_vpc_security_group" "internal" {
  name        = "internal-sg"
  description = "Internal security group for all VMs"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description = "SSH from bastion"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["10.0.10.0/24"]
  }

  ingress {
    description = "Allow internal traffic"
    protocol    = "ANY"
    port        = -1
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outgoing"
    protocol    = "ANY"
    port        = -1
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для web-серверов
resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description = "HTTP from ALB"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Node Exporter from internal"
    protocol    = "TCP"
    port        = 9100
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Nginx Log Exporter from internal"
    protocol    = "TCP"
    port        = 4040
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outgoing"
    protocol    = "ANY"
    port        = -1
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}