provider "google" {
 credentials =  "${file("credentials.json")}"
 project     = "${var.project_id}"
 region      = "${var.region}"
}

provider "kubernetes" {
    host                     = "${google_container_cluster.primary.endpoint}"
    token                    = "${data.google_client_config.current.access_token}"
    cluster_ca_certificate   = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}

provider "helm" {
  tiller_image               = "gcr.io/kubernetes-helm/tiller:v2.12.1"
  service_account            = "tiller"
  install_tiller             = true
  kubernetes {
    host                     = "${google_container_cluster.primary.endpoint}"
    token                    = "${data.google_client_config.current.access_token}"
    cluster_ca_certificate   = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  }
}