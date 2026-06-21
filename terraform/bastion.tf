# Bastion host (единственная точка входа)
resource "yandex_compute_instance" "bastion" {
  depends_on = [
    time_sleep.wait_before_bastion,
    yandex_compute_instance.web[0],
    yandex_compute_instance.web[1],
    yandex_compute_instance.grafana,
    yandex_compute_instance.kibana
  ]
  name                      = "${var.project_name}-bastion"
  hostname                  = "${var.project_name}-bastion"
  platform_id               = "standard-v2"
  zone                      = var.yc_zones[0]
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public[0].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/bastion-cloud-init.yml.tpl", {
      web_private_ips    = [for inst in yandex_compute_instance.web : inst.network_interface[0].ip_address]
      grafana_private_ip = yandex_compute_instance.grafana.network_interface[0].ip_address
      kibana_private_ip  = yandex_compute_instance.kibana.network_interface[0].ip_address
      ssh_public_key     = file(var.ssh_public_key_path)
    })
    # Передаём SSH ключ на Bastion
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}