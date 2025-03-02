terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  service_account_key_file = "${path.module}/key.json"
}

# --- IAM Service Account ---
resource "yandex_iam_service_account" "my_service_account" {
  name        = "terraform-sd"
  description = "Service account for managing Kubernetes"
}

# Назначение ролей для Service Account
resource "yandex_resourcemanager_folder_iam_binding" "k8s_binding" {
  folder_id = var.yc_folder_id
  role      = "resource-manager.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.my_service_account.id}"
  ]
}

resource "yandex_storage_bucket" "my_bucket" {
  bucket = "trututu"
  default_storage_class = "STANDARD"
}

# --- VPC Сеть ---
resource "yandex_vpc_network" "my_network" {
  name = "my-k8s-network"
}

# --- Подсети для регионального кластера ---
resource "yandex_vpc_subnet" "subnet-a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_subnet" "subnet-c" {
  name           = "subnet-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.my_network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}

# --- Региональный кластер Kubernetes ---
resource "yandex_kubernetes_cluster" "my_cluster" {
  name        = "my-k8s-cluster"
  description = "Regional Kubernetes cluster"
  network_id  = yandex_vpc_network.my_network.id
  folder_id   = var.yc_folder_id

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = "ru-central1-a"
        subnet_id = yandex_vpc_subnet.subnet-a.id
      }

      location {
        zone      = "ru-central1-b"
        subnet_id = yandex_vpc_subnet.subnet-b.id
      }

      location {
        zone      = "ru-central1-c"
        subnet_id = yandex_vpc_subnet.subnet-c.id
      }
    }

    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.my_service_account.id
  node_service_account_id = yandex_iam_service_account.my_service_account.id
}

# --- Группа узлов (Node Group) ---
resource "yandex_kubernetes_node_group" "my_node_group" {
  cluster_id   = yandex_kubernetes_cluster.my_cluster.id
  name         = "k8s-node-group"
  description  = "Managed Kubernetes node group"

  instance_template {
    platform_id = "standard-v2"

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      size = 50
    }

    network_interface {
      subnet_ids = [
        yandex_vpc_subnet.subnet-a.id,
        yandex_vpc_subnet.subnet-b.id,
        yandex_vpc_subnet.subnet-c.id
      ]
      nat = true
    }

    metadata = {
      ssh-keys = var.ssh_public_key
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }
}
