# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

# -----------------------------------------------------------------------------
# Default parameters.
# -----------------------------------------------------------------------------

locals {
  domain  = "${lookup(var.cloud, "name", "cloud.local")}"
  region  = "${lookup(var.cloud, "region", "ru-1")}"
  zone    = "${lookup(var.cloud, "zone", "ru-1a")}"

  lan = "${map(
    "name",     "${lookup(var.lan, "name", "${local.domain}")}",
    "cidr",     "${lookup(var.lan, "cidr", "192.168.0.0/24")}",
    "gateway",  "${lookup(var.lan, "gateway", "")}"
  )}"

  wan = "${map(
    "uuid",     "${lookup(var.wan, "uuid", "")}",
    "name",     "${lookup(var.wan, "name", "")}",
  )}"

  external = "${data.openstack_networking_network_v2.wan.external}"
}

# -----------------------------------------------------------------------------
# Public network.
# -----------------------------------------------------------------------------

data "openstack_networking_network_v2" "wan" {
  region      = "${local.region}"
  name        = "${local.wan["name"]}"
  network_id  = "${local.wan["uuid"]}"
}

data "openstack_networking_subnet_v2" "wan" {
  count       = "${local.external ? 0 : 1}"
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.wan.id}"
}

# -----------------------------------------------------------------------------
# Private network configuration.
# -----------------------------------------------------------------------------

resource "openstack_networking_network_v2" "lan" {
  region  = "${local.region}"
  name    = "${local.lan["name"]}"
}

resource "openstack_networking_subnet_v2" "lan" {
  region          = "${local.region}"
  network_id      = "${openstack_networking_network_v2.lan.id}"
  name            = "${local.lan["name"]}"
  cidr            = "${local.lan["cidr"]}"
  gateway_ip      = "${local.lan["gateway"]}"
  dns_nameservers = "${var.dns}"
}

resource "openstack_networking_port_v2" "router" {
  count           = "${local.external ? 1 : 0}"
  region          = "${local.region}"
  network_id      = "${openstack_networking_network_v2.lan.id}"
  name            = "${data.openstack_networking_network_v2.wan.name}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${openstack_networking_subnet_v2.lan.id}"
    ip_address  = "${openstack_networking_subnet_v2.lan.gateway_ip}"
  }
}

resource "openstack_networking_router_v2" "router" {
  count               = "${local.external ? 1 : 0}"
  region              = "${local.region}"
  name                = "${local.lan["name"]}"
  external_network_id = "${data.openstack_networking_network_v2.wan.id}"
  admin_state_up      = true
}

resource "openstack_networking_router_interface_v2" "router" {
  count     = "${local.external ? 1 : 0}"
  region    = "${local.region}"
  router_id = "${openstack_networking_router_v2.router.id}"
  port_id   = "${openstack_networking_port_v2.router.id}"
}
