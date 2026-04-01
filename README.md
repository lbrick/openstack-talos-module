# openstack-talos-module

This Terraform module provisions the necessary infrastructure to run a Kubernetes cluster using [Talos Linux](https://www.talos.dev/) on OpenStack.

It currently handles the creation of security groups and rules required for a functional and secure cluster, including support for Calico networking and remote management.

## Features

- **Security Groups**: Separate groups for Control Plane and Worker nodes.
- **In-Cluster Communication**: Pre-configured rules for intra-cluster traffic.
- **Calico Support**: Ingress rules for BGP (TCP 179) and IP-in-IP (Protocol 4).
- **Remote Management**: Controlled access to the Kubernetes API (6443) and Talos API (50000) via configurable source IPs.
- **Customizable Networking**: Support for Flannel, Calico, and Cilium CNIs.

## Usage

```hcl
module "kubernetes_cluster" {
  source = "github.com/lbrick/openstack-talos-module"

  cluster_name       = "kahu-test"
  kubernetes_version = "v1.35.2"
  key_pair           = "kahu-key"

  source_ips = [
    "10.1.0.0/24",
    "203.211.105.199/32"
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
| talos | >= 0.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Cluster name prefix used for resource naming. | `string` | n/a | yes |
| source_ips | List of source IP CIDRs allowed to access the Kubernetes API. | `list(string)` | n/a | yes |
| kubernetes_version | The version of Kubernetes to deploy. | `string` | n/a | yes |
| talos_version | The version of Talos Linux to use. | `string` | `"v1.12.6"` | no |
| key_pair | The name of the OpenStack key pair to use. | `string` | n/a | yes |
| controlplane_count | Number of control plane nodes. | `number` | `1` | no |
| worker_count | Number of worker nodes. | `number` | `2` | no |
| node_image | The name or ID of the Talos Linux image. | `string` | n/a | yes |
| image_visibility | Visibility of the Glance image (public/private). | `string` | `"public"` | no |
| network_name | The name of the OpenStack network to attach nodes to. | `string` | n/a | yes |
| access_network | Whether to enable the access network. | `bool` | `false` | no |
| node_volume_size | Size of the root volume in GB. | `string` | `"30"` | no |
| delete_volume_on_termination | Delete root volume on instance deletion. | `bool` | `true` | no |
| controlplane_flavor | OpenStack flavor for control plane nodes. | `string` | `"balanced1.2cpu4ram"` | no |
| worker_flavor | OpenStack flavor for worker nodes. | `string` | `"balanced1.4cpu8ram"` | no |
| clouds_yaml_path | Path to the OpenStack clouds.yaml file. | `string` | `"./clouds.yaml"` | no |
| os_cloud_name | The name of the cloud to use from clouds.yaml. | `string` | `"openstack"` | no |
| os_floating_network_id | ID of the floating network for the LoadBalancer. | `string` | `"3f405...d5"` | no |
| os_lb_provider | The OpenStack LoadBalancer provider (e.g., ovn). | `string` | `"ovn"` | no |
| cni_type | CNI to use. Options: `flannel`, `calico`, `cilium`. | `string` | `"flannel"` | no |
| cni_url_defaults | Map of default manifest URLs for CNIs. | `map(string)` | (see `variables.tf`) | no |
| extra_manifests | Main list of manifests (metrics-server, etc). | `list(string)` | (see `variables.tf`) | no |
| additional_manifests | Extra manifests to append to the base list. | `list(string)` | `[]` | no |
| external_cloud_manifests | Manifests for the OpenStack Cloud Controller Manager. | `list(string)` | (see `variables.tf`) | no |
| additional_cloud_manifests | Extra cloud manifests to append. | `list(string)` | `[]` | no |

## Security Details

### ⚠️ Production Warning: Cilium Manifests

The Cilium manifests provided in `manifests/cni/cilium/` are intended for **demonstration and testing purposes only**.

**Crucial Security Risk:** These manifests contain hardcoded certificates and private keys (secrets) that are publicly available in this repository. Using them in a production environment allows anyone with access to the repo to compromise your cluster networking.

### Steps for Production CNI Deployment

To securely deploy Cilium in production, you must generate your own manifests with unique secrets example can also be found on the Talos documentation [here](https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#method-2-helm-manifests-install):

1.  **Generate a Secure Manifest**:
    Use Helm to template Cilium with auto-generated secrets:
    ```bash
    helm template \
      cilium \
      cilium/cilium \
      --version 1.18.0 \
      --namespace kube-system \
      --set ipam.mode=kubernetes \
      --set kubeProxyReplacement=true \
      --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
      --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
      --set cgroup.autoMount.enabled=false \
      --set cgroup.hostRoot=/sys/fs/cgroup \
      --set k8sServiceHost=localhost \
      --set k8sServicePort=7445 > cilium.yaml
    ```
2.  **Host the Manifest**:
    Upload `my-secure-cilium.yaml` to a private web server, a secure S3/Swift bucket, or a private GitHub repository accessible to your provisioning environment.
3.  **Override the URL in Terraform**:
    When calling this module, point to your secure URL:
    ```hcl
    module "kubernetes_cluster" {
      # ... other config ...
      cni_type = "cilium"
      cni_url_defaults = {
        cilium = "https://your-secure-storage.internal/my-secure-cilium.yaml"
        calico = "https://raw.githubusercontent.com/projectcalico/..."
        flannel = ""
      }
    }
    ```

### Default Security Groups

The module creates the following security rules by default:

1.  **Control Plane**:
    - All ingress from other Control Plane nodes.
    - All ingress from Worker nodes.
    - TCP 6443 (K8s API) from `source_ips`.
    - TCP 50000 (Talos API) from `source_ips`.
2.  **Workers**:
    - TCP 50000 (Talos API) from `source_ips`.