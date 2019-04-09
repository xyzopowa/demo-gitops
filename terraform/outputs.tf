output "public_key" {
  value = "${tls_private_key.flux_repo.public_key_openssh}"
  description = "The public key to add to your github repo"
}