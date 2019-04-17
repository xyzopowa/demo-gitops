### Get Kubernetes authentification token

data "google_client_config" "current" {
}

## Tiller service account

resource "kubernetes_service_account" "tiller" {
  metadata {
    name = "tiller"
    namespace = "kube-system"
  }
  automount_service_account_token = "true"
}

resource "kubernetes_cluster_role_binding" "tiller" {
  depends_on = [ "kubernetes_service_account.tiller" ]
  lifecycle {
    ignore_changes = ["*"]
  }
  metadata {
    name = "tiller"
  }

  subject {
    kind = "User"
    name = "system:serviceaccount:kube-system:tiller"
  }

  role_ref {
    kind  = "ClusterRole"
    name = "cluster-admin"
  }
}

### Flux deployment

resource "tls_private_key" "flux_repo" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "kubernetes_secret" "git-flux" {
  depends_on = ["kubernetes_namespace.gitops-demo"]
  metadata {
    name = "flux-git-deploy"
    namespace = "flux"
  }
  data {
    identity = "${tls_private_key.flux_repo.private_key_pem}"
  }
  type = "Opaque"
}

resource "kubernetes_namespace" "gitops-demo" {
  depends_on  = ["google_container_cluster.primary"]
  metadata {
    name = "flux"
  }
}

data "helm_repository" "weaveworks" {
    name = "weaveworks"
    url  = "https://weaveworks.github.io/flux"
}

resource "helm_release" "flux" {
  depends_on = ["google_container_cluster.primary","kubernetes_cluster_role_binding.tiller"]
  name       = "flux"
  namespace  = "flux"
  repository = "weaveworks"
  chart      = "flux"
  version    = "0.9.0"

  values = [
    "${file("values.yaml")}"
  ]
}

### Github deploy key

resource "github_repository_deploy_key" "add_flux_key" {
    depends_on  = ["tls_private_key.flux_repo"]
    title = "flux key"
    repository = "${var.git_repo}"
    key = "${tls_private_key.flux_repo.public_key_openssh}"
    read_only = "false"
}
