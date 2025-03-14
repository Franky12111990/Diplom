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
