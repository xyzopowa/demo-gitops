resource "google_container_cluster" "primary" {
  name                     = "${var.name}"
  location                 = "${var.region}-${var.zones[0]}"
  network                  = "${google_compute_network.vpc.name}"
  subnetwork               = "${google_compute_subnetwork.subnet.name}"
  initial_node_count       = "${var.node_count}"

  master_authorized_networks_config {
    cidr_blocks = ["${var.master_authorized_networks_config}"]
  }
   depends_on    = ["google_compute_subnetwork.subnet"]
}