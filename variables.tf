
######################

variable "cluster_name" {
  type        = string
  description = "Cluster name prefix"
}

variable "source_ips" {
  type        = list(string)
  description = "List of source IP CIDRs allowed to access the Kubernetes API"
}

variable "kubernetes_version" {
    type = string
}

variable "talos_version" {
    type = string
    default = "v1.12.6"
}

variable "key_pair" {
    type = string
}

variable "controlplane_count" {
  default = 1
}

variable "worker_count" {
  default = 2
}

variable "node_image" {
    type = string
}

variable "image_visibility" {
    type = string
    default = "public"
}

variable "network_name" {
    type = string
}

variable "access_network" {
    type = bool
    default = false
}

variable "node_volume_size" {
    type = string
    default = "30"
}

variable "delete_volume_on_termination" {
    type = bool
    default = true
}

variable "controlplane_flavor" {
    type = string
    default = "balanced1.2cpu4ram"
}

variable "worker_flavor" {
    type = string
    default = "balanced1.4cpu8ram"
}