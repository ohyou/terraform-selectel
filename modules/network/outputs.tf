# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

output "lan" {
  description = "Private network information"
  value       = "${map(
    "uuid",     "${openstack_networking_network_v2.lan.id}",
    "name",     "${openstack_networking_network_v2.lan.name}",
    "cidr",     "${openstack_networking_subnet_v2.lan.cidr}",
    "gateway",  "${openstack_networking_subnet_v2.lan.gateway_ip}",
  )}"

  depends_on = [
    "openstack_networking_router_interface_v2.router",
  ]
}

output "wan" {
  description = "Public network information"
  value       = "${map(
    "uuid",     "${data.openstack_networking_network_v2.wan.id}",
    "name",     "${data.openstack_networking_network_v2.wan.name}",
    "cidr",     "${join("", data.openstack_networking_subnet_v2.wan.*.cidr)}",
    "external", "${local.external}",
  )}"

  depends_on = [
    "openstack_networking_router_interface_v2.router",
  ]
}

output "router" {
  description = "Router information",
  value       = "${map(
    "uuid", "${join("", openstack_networking_router_v2.router.*.id)}",
    "name", "${join("", openstack_networking_router_v2.router.*.name)}",
    "port", "${join("", openstack_networking_port_v2.router.*.id)}"
  )}"
}
