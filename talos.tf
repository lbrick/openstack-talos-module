resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${openstack_networking_floatingip_v2.kubeapi_floatip.address}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            cloud-provider = "external"
            "rotate-server-certificates" = true
          }
        }
        install = {
          extraKernelArgs = ["talos.config=none", "talos.experimental.wipe=system"]
        }
      }
      cluster = merge(
        {
          controllerManager = {
            extraArgs = {
              cloud-provider = "external"
            }
          }
          extraManifests = concat(var.extra_manifests, var.additional_manifests)
          inlineManifests = [
            {
              name = "openstack-cloud-controller-config"
              contents = yamlencode({
                apiVersion = "v1"
                kind       = "Secret"
                type       = "Opaque"
                metadata = {
                  name      = "cloud-config"
                  namespace = "kube-system"
                }
                data = {
                  "cloud.conf" = base64encode(local.occm_conf)
                }
              })
            }
          ]
          externalCloudProvider = {
            enabled   = true
            manifests = concat(var.external_cloud_manifests, var.additional_cloud_manifests)
          }
        },

        # Conditional Network (only if not flannel)
        var.cni_type != "flannel" ? {
          network = {
            #dnsDomain      = domain
            #podSubnets     = split(",", podSubnets)
            #serviceSubnets = split(",", serviceSubnets)
            cni = {
              name = "custom"
              urls = [local.active_cni_url]
            }
          }
        } : {},

        # Conditional Proxy (only if cilium)
        var.cni_type == "cilium" ? {
          proxy = {
            disabled = true
          }
        } : {}
      )
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${openstack_networking_floatingip_v2.kubeapi_floatip.address}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        install = {
          # This forces the machine to wipe and stay in maintenance
          extraKernelArgs = ["talos.config=none", "talos.experimental.wipe=system"]
        }
        kubelet = {
          extraArgs = {
            cloud-provider = "external"
            rotate-server-certificates = true
          }
        }
      }
    })
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for v in local.cp_instances : v.internal_ip]
}

# Finalize configuration for the FIRST control plane node
resource "talos_machine_configuration_apply" "controlplane_init" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = local.cp_instances["0"].internal_ip
  config_patches = [
    yamlencode({
      machine = {
        certSANs = [
          openstack_networking_floatingip_v2.kubeapi_floatip.address
        ]
      }
    })
  ]
}

# Bootstrap the cluster (Executes talosctl bootstrap on Node 0)
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_instances["0"].internal_ip

  depends_on = [
    talos_machine_configuration_apply.controlplane_init
  ]
}

# Finalize configuration for joining control plane nodes
resource "talos_machine_configuration_apply" "controlplane_join" {
  for_each                    = { for k, v in local.cp_instances : k => v if k != "0" }
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.internal_ip
  config_patches = [
    yamlencode({
      machine = {
        certSANs = [
          openstack_networking_floatingip_v2.kubeapi_floatip.address
        ]
      }
    })
  ]

  depends_on = [
    talos_machine_bootstrap.this
  ]
}

# Finalize configuration for worker nodes
resource "talos_machine_configuration_apply" "worker" {
  for_each                    = local.worker_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.internal_ip

  depends_on = [
    talos_machine_bootstrap.this
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_instances["0"].internal_ip

  depends_on = [talos_machine_bootstrap.this]
}

resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.root}/kubeconfig"
}