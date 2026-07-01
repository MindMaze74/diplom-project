# Целевая группа (список целей)
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group"

  target {
    ip_address   = yandex_compute_instance.web[0].network_interface.0.ip_address
    subnet_id    = yandex_vpc_subnet.private[0].id
  }
  target {
    ip_address   = yandex_compute_instance.web[1].network_interface.0.ip_address
    subnet_id    = yandex_vpc_subnet.private[1].id
  }

  depends_on = [
    yandex_compute_instance.web[0],
    yandex_compute_instance.web[1]
  ]
}

# Бэкенд-группа с health check
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group"

  http_backend {
    name = "web-http-backend"
    port = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout = "5s"
      interval = "10s"
      healthy_threshold = 2
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"
        # port не указываем, будет использован порт бэкенда
      }
    }
  }
}

# HTTP-роутер
resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

# Виртуальный хост
resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-vhost"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "default-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout = "60s"
      }
    }
  }
}

# Балансировщик
resource "yandex_alb_load_balancer" "web_lb" {
  name        = "web-lb"
  network_id  = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public[0].id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public[1].id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {
          # автоматически получит публичный IP
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  depends_on = [
    yandex_alb_target_group.web_tg,
    yandex_alb_backend_group.web_bg,
    yandex_alb_http_router.web_router
  ]
}