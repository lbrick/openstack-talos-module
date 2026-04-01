
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

variable "cni_type" {
  description = "CNI to use. Options: flannel, calico, cilium"
  type        = string
  default     = "flannel"

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni_type)
    error_message = "cni_type must be one of: flannel, calico, cilium."
  }
}

variable "cni_url_defaults" {
  type = map(string)
  default = {
    cilium = "https://raw.githubusercontent.com/sergelogvinov/terraform-talos/main/_deployments/vars/cilium-result.yaml"
    calico = "https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml"
    flannel = "" # Flannel is built-in to Talos, usually doesn't need a URL
  }
}
variable "extra_manifests" {
  description = "The main/base list of manifests"
  type        = list(string)
  default     = [
    "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml",
    "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
  ]
}

variable "additional_manifests" {
  description = "Additional manifests to append to the base list"
  type        = list(string)
  default     = []
}

variable "external_cloud_manifests" {
  description = "List of manifests for the external cloud provider"
  type        = list(string)
  default     = [
    "https://raw.githubusercontent.com/lbrick/openstack-talos-module/refs/heads/main/manifests/controller-manager/v1.35.0/openstack-cloud-controller-manager.yaml"
  ]
}

variable "additional_cloud_manifests" {
  description = "Additional manifests to append to the base list"
  type        = list(string)
  default     = []
}