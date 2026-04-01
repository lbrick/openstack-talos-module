resource "openstack_networking_floatingip_v2" "kubeapi_floatip" {
    pool = "external"
    description = "Created for k8s-${var.cluster_name}-kubeapi loadbalancer"
}

resource "openstack_networking_floatingip_associate_v2" "kubeapi_floatip_associate" {
    floating_ip = openstack_networking_floatingip_v2.kubeapi_floatip.address
    port_id     = openstack_lb_loadbalancer_v2.kubeapi_lb.vip_port_id
}

resource "openstack_lb_loadbalancer_v2" "kubeapi_lb" {
    name = "k8s-${var.cluster_name}-kubeapi"
    vip_subnet_id = data.openstack_networking_network_v2.this.subnets[0]
    loadbalancer_provider = "ovn"
}

resource "openstack_lb_listener_v2" "kubeapi_6443_listener" {
    name            = "k8s-${var.cluster_name}-kubeapi-6443"
    protocol        = "TCP"
    protocol_port   = 6443
    loadbalancer_id = resource.openstack_lb_loadbalancer_v2.kubeapi_lb.id
}

resource "openstack_lb_pool_v2" "kubeapi_6443_pool" {
    name        = "k8s-${var.cluster_name}-kubeapi-6443"
    protocol    = "TCP"
    lb_method   = "SOURCE_IP_PORT"
    listener_id = resource.openstack_lb_listener_v2.kubeapi_6443_listener.id
}

resource "openstack_lb_monitor_v2" "kubeapi_6443_monitor" {
    name        = "k8s-${var.cluster_name}-kubeapi-6443"
    pool_id     = resource.openstack_lb_pool_v2.kubeapi_6443_pool.id
    type        = "TCP"
    delay       = 10
    timeout     = 5
    max_retries = 5
    max_retries_down = 3
}

resource "openstack_lb_member_v2" "kubeapi_6443_members" {
    for_each      = local.cp_instances

    name          = each.value.hostname
    pool_id       = resource.openstack_lb_pool_v2.kubeapi_6443_pool.id
    address       = each.value.internal_ip
    protocol_port = 6443
    subnet_id     = data.openstack_networking_network_v2.this.subnets[0]
}