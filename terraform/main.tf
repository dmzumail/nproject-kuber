# DNS-зона
resource "yandex_dns_zone" "public" {
  name        = "zone-nproject-site"
  description = "Public DNS zone for nproject.site"
  zone        = "nproject.site."
  public      = true
}

# Сеть и подсеть
resource "yandex_vpc_network" "default" {
  name = "net-nproject-site"
}

resource "yandex_vpc_subnet" "default" {
  name           = "subnet-nproject-site"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# IAM Service Account для Kubernetes
resource "yandex_iam_service_account" "k8s_sa" {
  name        = "sa-k8s-nproject-site"
  description = "Service account for Kubernetes cluster and node group"
}

# Минимально необходимые IAM-роли
resource "yandex_resourcemanager_folder_iam_member" "k8s_roles" {
  for_each = toset([
    "k8s.clusters.agent",
    "vpc.admin",
    "load-balancer.admin",
    "container-registry.images.puller",
    "compute.viewer",
    "iam.serviceAccounts.user"
    # "certificate-manager.certificates.user" ← раскомментировать позже, если нужен HTTPS
  ])

  folder_id = var.yc_folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Container Registry
resource "yandex_container_registry" "default" {
  name = "cr-nproject-site"
}

# Kubernetes Cluster (версия 1.29 + ПРАВИЛЬНЫЕ аргументы CIDR)
resource "yandex_kubernetes_cluster" "k8s" {
  name               = "k8s-nproject-site"
  network_id         = yandex_vpc_network.default.id
  cluster_ipv4_range = "10.244.0.0/16" # ← правильно: _range
  service_ipv4_range = "10.96.0.0/16"  # ← правильно: _range

  master {
    version = "1.29"
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.default.id
    }
    public_ip = true
  }

  service_account_id       = yandex_iam_service_account.k8s_sa.id
  node_service_account_id  = yandex_iam_service_account.k8s_sa.id
  node_ipv4_cidr_mask_size = 24
}

# Node Group
resource "yandex_kubernetes_node_group" "k8s_nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "ng-nproject-site"
  version    = "1.29"

  instance_template {
    platform_id = "standard-v3"
    nat         = true # даёт исходящий интернет

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 20
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.default.id
    }
  }
}