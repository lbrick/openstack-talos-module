data "openstack_images_image_v2" "this" {
  name        = var.node_image
  most_recent = true
  visibility = var.image_visibility
}

data "openstack_compute_flavor_v2" "controlplane_flavor_data" {
  name = var.controlplane_flavor
}

data "openstack_compute_flavor_v2" "worker_flavor_data" {
  name = var.worker_flavor
}

# Private network
data "openstack_networking_network_v2" "this" {
  name = var.network_name
}

# External network
data "openstack_networking_port_v2" "this_external" {
  network_id   = data.openstack_networking_network_v2.this.id
  device_owner = "network:router_interface"
}

data "openstack_networking_router_v2" "this" {
  router_id = data.openstack_networking_port_v2.this_external.device_id
}

data "openstack_networking_network_v2" "this_external" {
  network_id = data.openstack_networking_router_v2.this.external_network_id
}