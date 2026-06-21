# Виртуальные машины

# Веб-серверы (2 шт, в разных зонах)
resource "yandex_compute_instance" "web" {
  count = 2

  name        = "${var.project_name}-web-${count.index + 1}"
  hostname    = "${var.project_name}-web-${count.index + 1}"
  platform_id = "standard-v2"
  zone        = var.yc_zones[count.index]

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
    subnet_id          = yandex_vpc_subnet.private[count.index].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id, yandex_vpc_security_group.internal.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
      ssh_public_key = file(var.ssh_public_key_path)
    })
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Prometheus
resource "yandex_compute_instance" "prometheus" {
  depends_on = [time_sleep.wait_for_instances]

  name        = "${var.project_name}-prometheus"
  hostname    = "${var.project_name}-prometheus"
  platform_id = "standard-v2"
  zone        = var.yc_zones[0]

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 30
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private[0].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
      ssh_public_key = file(var.ssh_public_key_path)
    })
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Grafana
resource "yandex_compute_instance" "grafana" {
  depends_on = [time_sleep.wait_for_instances]

  name        = "${var.project_name}-grafana"
  hostname    = "${var.project_name}-grafana"
  platform_id = "standard-v2"
  zone        = var.yc_zones[0]

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
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
    subnet_id          = yandex_vpc_subnet.private[0].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
      ssh_public_key = file(var.ssh_public_key_path)
    })
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Elasticsearch
resource "yandex_compute_instance" "elasticsearch" {
  depends_on = [time_sleep.wait_for_instances]

  name        = "${var.project_name}-elasticsearch"
  hostname    = "${var.project_name}-elasticsearch"
  platform_id = "standard-v2"
  zone        = var.yc_zones[0]

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 30
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private[0].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
      ssh_public_key = file(var.ssh_public_key_path)
    })
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Kibana
resource "yandex_compute_instance" "kibana" {
  depends_on = [time_sleep.wait_for_instances]

  name        = "${var.project_name}-kibana"
  hostname    = "${var.project_name}-kibana"
  platform_id = "standard-v2"
  zone        = var.yc_zones[0]

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
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
    subnet_id          = yandex_vpc_subnet.private[0].id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tpl", {
      ssh_public_key = file(var.ssh_public_key_path)
    })
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }
}
