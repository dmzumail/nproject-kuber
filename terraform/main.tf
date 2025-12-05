# Генерация уникального суффикса для избежания конфликтов имён (особенно для registry)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  lower   = true
}

# Публичная DNS-зона для nproject.site
resource "yandex_dns_zone" "public" {
  name        = "zone-nproject-site"
  description = "Public DNS zone for nproject.site"
  zone        = "nproject.site."
  public      = true
}

# VPC: сеть и подсеть
resource "yandex_vpc_network" "default" {
  name = "net-nproject-site"
}

resource "yandex_vpc_subnet" "default" {
  name           = "subnet-nproject-site"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Сервисный аккаунт для Kubernetes
resource "yandex_iam_service_account" "k8s_sa" {
  name        = "sa-k8s-nproject-site"
  description = "Service account for Kubernetes cluster"
}

# IAM: роль editor на папку
resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# IAM: доступ к Container Registry
resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_registry_reader" {
  folder_id = var.yc_folder_id
  role      = "container-registry.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Container Registry с уникальным именем
resource "yandex_container_registry" "default" {
  name = "cr-nproject-site-${random_string.suffix.result}"
}

# Kubernetes Cluster (без логирования)
resource "yandex_kubernetes_cluster" "k8s" {
  name               = "k8s-nproject-site-v2"
  network_id         = yandex_vpc_network.default.id
  cluster_ipv4_range = "10.244.0.0/16"
  service_ipv4_range = "10.96.0.0/16"

  master {
    version   = "1.30"
    public_ip = true

    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.default.id
    }
  }

  service_account_id       = yandex_iam_service_account.k8s_sa.id
  node_service_account_id  = yandex_iam_service_account.k8s_sa.id
  node_ipv4_cidr_mask_size = 24

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_sa_editor,
    yandex_resourcemanager_folder_iam_member.k8s_sa_registry_reader
  ]

  timeouts {
    create = "45m"
    update = "30m"
    delete = "20m"
  }
}

# Группа узлов Kubernetes
resource "yandex_kubernetes_node_group" "k8s_nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "ng-nproject-site-v2"
  version    = "1.30"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.default.id]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}

# DNS A-записи
resource "yandex_dns_recordset" "site" {
  count   = var.external_ip != "" ? 1 : 0
  zone_id = yandex_dns_zone.public.id
  name    = "${var.domain}."
  type    = "A"
  ttl     = 300
  data    = [var.external_ip]
}

resource "yandex_dns_recordset" "www" {
  count   = var.external_ip != "" ? 1 : 0
  zone_id = yandex_dns_zone.public.id
  name    = "www.${var.domain}."
  type    = "A"
  ttl     = 300
  data    = [var.external_ip]
}