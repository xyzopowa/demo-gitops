##########################
###      CLUSTER       ###
##########################

variable "name" {
  type        = "string"
  description = "Kubernetes cluster name"
}

variable "project_id" {
  type        = "string"
  description = "Google Cloud project name"
}

variable "network" {
  type        = "string"
  description = "Network to create the cluster in"
  default = ""
}

variable "subnetwork" {
  type        = "string"
  description = "Subnetwork"
  default = ""
}

variable "region" {
  description = "Kubernetes cluster region"
}

variable "zones" {
  type        = "list"
  description = "Zones for Kubernetes workers"
  default     = ["b", "c"]
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  default = "3"
}

variable "master_authorized_networks_config" {
  description = "The Kubernetes labels (key/value pairs) to be applied to each node"
  type        = "map"
  default     = { cidr_block = "0.0.0.0/0", display_name = "ANY" }
}

##########################
###         VPC        ###
##########################

variable "subnet_cidr" {
  type        = "string"
  description = "subnetwork"
  default = "10.164.0.0/20"
}

##########################
###    POST-INSTALL    ###
##########################

variable "git_repo" {
  description = "Repo to sync with weave flux"
}

variable "git_branch" {
  description = "Branch of the flux repo"
  default = "master"
}