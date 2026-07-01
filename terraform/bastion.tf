resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id   # Ubuntu 22.04 LTS
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public[0].id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    user-data = <<-EOF
      #cloud-config
      package_upgrade: true
      packages:
        - docker.io
        - docker-compose
      runcmd:
        - systemctl enable docker
        - systemctl start docker
        # Устанавливаем Nginx только для прокси Grafana/Kibana (если нужно)
        - apt-get update && apt-get install -y nginx
        # Здесь может быть ваша конфигурация Nginx для Grafana/Kibana
    EOF
  }
}