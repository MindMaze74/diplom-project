# Сетевая инфраструктура
resource "yandex_vpc_network" "main" { name = "${var.project_name}-network" }

resource "yandex_vpc_subnet" "private" {
  count = length(var.yc_zones)
  name = "${var.project_name}-private-${var.yc_zones[count.index]}"
  zone = var.yc_zones[count.index]
  network_id = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.${count.index + 1}.0/24"]
  route_table_id = yandex_vpc_route_table.nat.id
}

resource "yandex_vpc_subnet" "public" {
  count = length(var.yc_zones)
  name = "${var.project_name}-public-${var.yc_zones[count.index]}"
  zone = var.yc_zones[count.index]
  network_id = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.${count.index + 10}.0/24"]
}

resource "yandex_vpc_gateway" "nat_gateway" { name = "${var.project_name}-nat-gateway" }
resource "yandex_vpc_route_table" "nat" {
  name = "${var.project_name}-nat-route-table"
  network_id = yandex_vpc_network.main.id
  static_route { destination_prefix = "0.0.0.0/0" gateway_id = yandex_vpc_gateway.nat_gateway.id }
}
