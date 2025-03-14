resource "yandex_iam_service_account" "my_service_account" {
  name        = "terraform-sd"
  description = "Service account for managing Kubernetes"
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s_binding" {
  folder_id = var.yc_folder_id
  role      = "resource-manager.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.my_service_account.id}"
  ]
}
