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
