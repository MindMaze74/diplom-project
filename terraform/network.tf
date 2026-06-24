# Сетевая инфраструктура

# Основная VPC-сеть
resource "yandex_vpc_network" "main" {
  name = "${var.project_name}-network"
}

# Приватные подсети (по одной на зону)
resource "yandex_vpc_subnet" "private" {
  count = length(var.yc_zones)

  name           = "${var.project_name}-private-${var.yc_zones[count.index]}"
  zone           = var.yc_zones[count.index]
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.${count.index + 1}.0/24"]
  route_table_id = yandex_vpc_route_table.nat.id
}

# Публичные подсети (по одной на зону)
resource "yandex_vpc_subnet" "public" {
  count = length(var.yc_zones)

  name           = "${var.project_name}-public-${var.yc_zones[count.index]}"
  zone           = var.yc_zones[count.index]
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.${count.index + 10}.0/24"]
}

# NAT-шлюз для выхода в интернет из приватных подсетей
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "${var.project_name}-nat-gateway"
  shared_egress_gateway {}
}

# Таблица маршрутизации с маршрутом по умолчанию через NAT
resource "yandex_vpc_route_table" "nat" {
  name       = "${var.project_name}-nat-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
