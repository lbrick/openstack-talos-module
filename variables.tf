
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

variable "clouds_yaml_path" {
  description = "Path to the OpenStack clouds.yaml file"
  type        = string
  default     = "./clouds.yaml"
}

variable "os_cloud_name" {
  description = "The name of the cloud to use from clouds.yaml"
  type        = string
  default     = "openstack"
}

variable "os_floating_network_id" {
  type        = string
  description = "The ID of the floating network for the LoadBalancer"
  default     = "3f405cc9-28a3-4973-b5a1-7f50f112e5d5"
}

variable "os_lb_provider" {
  type        = string
  default     = "ovn"
}

variable "cni_url" {
  description = "URL for the custom CNI manifest"
  type        = string
  default     = "https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/cilium-result.yaml"
}

variable "external_cloud_manifests" {
  description = "List of manifests for the external cloud provider"
  type        = list(string)
  default     = [
    "https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/talos-cloud-controller-manager-result.yaml",
    "https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cloud-controller-manager-result.yaml",
    "https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/openstack/deployments/openstack-cinder-csi-result.yaml"
  ]
}