# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

output "is_floating" {
  description = "Flag that indicates the usage of floating IP"
  value       = "${local.floating}"

  depends_on  = [
    "openstack_networking_router_interface_v2.router"
  ]
}

output "wan" {
  description = "Public network configuration"
  value       = {
    uuid    = "${data.openstack_networking_network_v2.wan.id}"
    name    = "${data.openstack_networking_network_v2.wan.name}"
    cidr    = "${coalesce(data.openstack_networking_subnet_v2.wan.*.cidr)}"
    gateway = "${coalesce(data.openstack_networking_subnet_v2.wan.*.gateway_ip)}"
  }

  depends_on  = [
    "openstack_networking_router_interface_v2.router"
  ]
}

output "lan" {
  description = "Private network configuration"
  value       = {
    uuid    = "${openstack_networking_network_v2.lan.id}"
    name    = "${local.lan["name"]}"
    cidr    = "${local.lan["cidr"]}"
    gateway = "${local.lan["gateway"]}"
  }

  depends_on  = [
    "openstack_networking_router_interface_v2.router"
  ]
}

output "dns" {
  description = "List of name servers"
  value       = "${var.dns}"

  depends_on  = [
    "openstack_networking_router_interface_v2.router"
  ]
}

output "pool" {
  description = "Private network address pool configuration"
  value       = "${local.pool}"

  depends_on  = [
    "openstack_networking_router_interface_v2.router"
  ]
}