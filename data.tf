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

locals {
  clouds_file = yamldecode(file(var.clouds_yaml_path))
  raw_cloud   = local.clouds_file.clouds[var.os_cloud_name]
  raw_auth    = local.raw_cloud.auth

  # Replicating the "Always App Creds" logic
  occm_conf = <<-EOT
    [Global]
    auth-url=${local.raw_auth.auth_url}
    application-credential-id="${local.raw_auth.application_credential_id}"
    application-credential-secret="${local.raw_auth.application_credential_secret}"
    region="${try(local.raw_cloud.region_name, "RegionOne")}"
    tls-insecure=true

    [LoadBalancer]
    lb-provider="${var.os_lb_provider}"
    lb-method="SOURCE_IP_PORT"
    floating-network-id="${var.os_floating_network_id}"
  EOT
}