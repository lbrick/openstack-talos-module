# Generate keys for for_each to replace count
locals {
  cp_keys     = [for i in range(var.controlplane_count) : tostring(i)]
  worker_keys = [for i in range(var.worker_count) : tostring(i)]
}

# Create control plane instance
resource "random_string" "controlplane_suffix" {
  for_each = toset(local.cp_keys)

  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "openstack_networking_port_v2" "controlplane_port" {
  for_each = toset(local.cp_keys)

  name = "${var.cluster_name}-control-plane-${random_string.controlplane_suffix[each.key].result}"
  network_id = data.openstack_networking_network_v2.this.id
  admin_state_up = true
  security_group_ids = [openstack_networking_secgroup_v2.controlplane.id]
}

resource "openstack_compute_instance_v2" "controlplane" {
  for_each = toset(local.cp_keys)

  name = "${var.cluster_name}-control-plane-${random_string.controlplane_suffix[each.key].result}"
  flavor_id = data.openstack_compute_flavor_v2.controlplane_flavor_data.id
  key_pair = var.key_pair

  # Merge base config with node-specific hostname at boot time
  user_data = data.talos_machine_configuration.controlplane.machine_configuration

  block_device {
    uuid                  = data.openstack_images_image_v2.this.id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = var.node_volume_size
    delete_on_termination = var.delete_volume_on_termination
  }

  network {
    port = openstack_networking_port_v2.controlplane_port[each.key].id
    access_network = var.access_network
  }
}

# Create worker instance
resource "random_string" "worker_suffix" {
  for_each = toset(local.worker_keys)

  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "openstack_networking_port_v2" "worker_port" {
  for_each = toset(local.worker_keys)

  name = "${var.cluster_name}-worker-${random_string.worker_suffix[each.key].result}"
  network_id = data.openstack_networking_network_v2.this.id
  admin_state_up = true
  security_group_ids = [openstack_networking_secgroup_v2.worker.id]
}

resource "openstack_compute_instance_v2" "worker" {
  for_each = toset(local.worker_keys)

  name = "${var.cluster_name}-worker-${random_string.worker_suffix[each.key].result}"
  flavor_id = data.openstack_compute_flavor_v2.worker_flavor_data.id
  key_pair = var.key_pair

  # Merge base config with node-specific hostname at boot time
  user_data = data.talos_machine_configuration.worker.machine_configuration

  block_device {
    uuid                  = data.openstack_images_image_v2.this.id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = var.node_volume_size
    delete_on_termination = var.delete_volume_on_termination
  }

  network {
    port = openstack_networking_port_v2.worker_port[each.key].id
    access_network = var.access_network
  }
}

# Generate instance maps for Talos resources
locals {
  cp_instances = {
    for k, instance in openstack_compute_instance_v2.controlplane :
    k => {
      hostname     = instance.name
      internal_ip  = instance.access_ip_v4
      install_disk = "/dev/vda"
    }
  }

  worker_nodes = {
    for k, instance in openstack_compute_instance_v2.worker :
    k => {
      hostname     = instance.name
      internal_ip  = instance.access_ip_v4
      install_disk = "/dev/vda"
    }
  }
}