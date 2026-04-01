# openstack-talos-module

This Terraform module provisions the necessary infrastructure to run a Kubernetes cluster using [Talos Linux](https://www.talos.dev/) on OpenStack.

It currently handles the creation of security groups and rules required for a functional and secure cluster, including support for Calico networking and remote management.

## Features

- **Security Groups**: Separate groups for Control Plane and Worker nodes.
- **In-Cluster Communication**: Pre-configured rules for intra-cluster traffic.
- **Calico Support**: Ingress rules for BGP (TCP 179) and IP-in-IP (Protocol 4).
- **Remote Management**: Controlled access to the Kubernetes API (6443) and Talos API (50000) via configurable source IPs.

## Usage

```hcl
module "kubernetes_cluster" {
  source = "github.com/lbrick/openstack-talos-module"

  cluster_name       = "cluster_name"
  kubernetes_version = "v1.35.2"
  key_pair           = "ssh_key_in_openstack"

  source_ips = [
    "10.1.0.0/24",
    "Your_home_ip/32"
  ]

  controlplane_count = 3
  worker_count       = 2

  network_name     = "openstack_project_network"
  node_image       = "talos-v1.12.6"
  image_visibility = "private"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| openstack | >= 1.48.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | The name of the cluster, used for naming resources. | `string` | n/a | yes |
| kubernetes_version | The version of Kubernetes to deploy (e.g., v1.35.2). | `string` | n/a | yes |
| key_pair | The name of the OpenStack key pair to use for the instances. | `string` | n/a | yes |
| source_ips | List of CIDRs allowed to access the K8s and Talos APIs. | `list(string)` | n/a | yes |
| controlplane_count | The number of control plane nodes to provision. | `number` | n/a | yes |
| worker_count | The number of worker nodes to provision. | `number` | n/a | yes |
| network_name | The name of the OpenStack network to attach the nodes to. | `string` | n/a | yes |
| node_image | The name or ID of the Talos Linux image to use. | `string` | n/a | yes |
| image_visibility | The visibility of the Glance image (e.g., public, private). | `string` | `"private"` | no |

## Security Details

The module creates the following security rules by default:

1.  **Control Plane**:
    - All ingress from other Control Plane nodes.
    - All ingress from Worker nodes.
    - TCP 6443 (K8s API) from `source_ips`.
    - TCP 50000 (Talos API) from `source_ips`.
2.  **Workers**:
    - TCP 50000 (Talos API) from `source_ips`.