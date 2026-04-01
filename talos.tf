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
        install = {
          # This forces the machine to wipe and stay in maintenance
          extraKernelArgs = ["talos.config=none", "talos.experimental.wipe=system"]
        }
      }
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