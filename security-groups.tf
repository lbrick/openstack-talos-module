resource "openstack_networking_secgroup_v2" "controlplane" {
  name        = "k8s-cluster-${var.cluster_name}-secgroup-controlplane"
  description = "Control plane security group"
}

resource "openstack_networking_secgroup_v2" "worker" {
  name        = "k8s-cluster-${var.cluster_name}-secgroup-worker"
  description = "Worker security group"
}

# --- Rules for control plane ingress from control plane and worker
resource "openstack_networking_secgroup_rule_v2" "in_cluster_ingress_cp_cp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "" # Empty string allows all protocols in Neutron
  remote_group_id   = openstack_networking_secgroup_v2.controlplane.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "In-cluster ingress (controlplane → controlplane)"
}

resource "openstack_networking_secgroup_rule_v2" "in_cluster_ingress_cp_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "" # Empty string allows all protocols in Neutron
  remote_group_id   = openstack_networking_secgroup_v2.worker.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "In-cluster ingress (worker → controlplane)"
}

# --- IP-in-IP (Calico)
resource "openstack_networking_secgroup_rule_v2" "ip_in_ip_cp_cp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = 4
  remote_group_id   = openstack_networking_secgroup_v2.controlplane.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "IP-in-IP (Calico)"
}

resource "openstack_networking_secgroup_rule_v2" "ip_in_ip_cp_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = 4
  remote_group_id   = openstack_networking_secgroup_v2.worker.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "IP-in-IP (Calico)"
}

# --- BGP (Calico)
resource "openstack_networking_secgroup_rule_v2" "bgp_cp_cp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = openstack_networking_secgroup_v2.controlplane.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "BGP (Calico)"
}

resource "openstack_networking_secgroup_rule_v2" "bgp_cp_worker" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 179
  port_range_max    = 179
  remote_group_id   = openstack_networking_secgroup_v2.worker.id
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "BGP (Calico)"
}

# --- Kubernetes API rule
resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  for_each          = toset(var.source_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "Kubernetes API"
}

# --- Talos API rule for remote management
resource "openstack_networking_secgroup_rule_v2" "talos_api_cp" {
  for_each          = toset(var.source_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 50000
  port_range_max    = 50000
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.controlplane.id
  description       = "Talos API Management (Control Plane)"
}

resource "openstack_networking_secgroup_rule_v2" "talos_api_worker" {
  for_each          = toset(var.source_ips)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 50000
  port_range_max    = 50000
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.worker.id
  description       = "Talos API Management (Worker)"
}