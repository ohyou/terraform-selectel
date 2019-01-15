# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

# -----------------------------------------------------------------------------
# Requirements.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12.0"
}

# -----------------------------------------------------------------------------
# Local variables.
# -----------------------------------------------------------------------------

locals {
  domain  = "${lookup(var.cloud, "name", "cloud.local")}"
  region  = "${lookup(var.cloud, "region", "ru-1")}"

  wan = {
    uuid  = "${lookup(var.wan, "uuid", "")}"
    name  = "${lookup(var.wan, "name", "")}"
  }

  lan = {
    name    = "${
      lookup(var.lan, "name", local.domain) == "" ?
      local.domain :
      lookup(var.lan, "name", local.domain)
    }"
    cidr    = "${lookup(var.lan, "cidr", "192.168.0.0/24")}"
    gateway = "${
      lookup(var.lan, "gateway", "") == "" ?
      cidrhost(lookup(var.lan, "cidr", "192.168.0.0/24"), 1) :
      lookup(var.lan, "gateway", "")
    }"
  }

  pool = "${
    length(var.pool) == 0 ?
    [{
      start: cidrhost(local.lan["cidr"], 2), 
      end: cidrhost(local.lan["cidr"], -2)
    }] :
    var.pool
  }"

  floating = "${data.openstack_networking_network_v2.wan.external}"
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
  count       = "${local.floating ? 0 : 1}"
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.wan.id}"
}

# -----------------------------------------------------------------------------
# Private network.
# -----------------------------------------------------------------------------

resource "openstack_networking_network_v2" "lan" {
  region          = "${local.region}"
  name            = "${local.lan["name"]}"
  admin_state_up  = true
}

resource "openstack_networking_subnet_v2" "lan" {
  region          = "${local.region}"
  name            = "${local.lan["name"]}"
  cidr            = "${local.lan["cidr"]}"
  network_id      = "${openstack_networking_network_v2.lan.id}"
  gateway_ip      = "${local.lan["gateway"]}"
  dns_nameservers = "${var.dns}"

  dynamic "allocation_pools" {
    for_each = "${local.pool}"

    content {
      start = "${allocation_pools.value["start"]}"
      end   = "${allocation_pools.value["end"]}"
    }
  }

  depends_on = [
    "openstack_networking_network_v2.lan"
  ]
}

resource "openstack_networking_router_v2" "router" {
  count               = "${local.floating ? 1 : 0}"
  region              = "${local.region}"
  name                = "${local.lan["name"]} router"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.wan.id}"
}

resource "openstack_networking_port_v2" "router" {
  count           = "${local.floating ? 1 : 0}"
  name            = "${local.lan["name"]} router"
  network_id      = "${openstack_networking_network_v2.lan.id}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${openstack_networking_subnet_v2.lan.id}"
    ip_address  = "${local.lan["gateway"]}"
  }

  depends_on = [
    "openstack_networking_subnet_v2.lan"
  ]
}

resource "openstack_networking_router_interface_v2" "router" {
  count     = "${local.floating ? 1 : 0}"
  region    = "${local.region}"
  router_id = "${openstack_networking_router_v2.router.*.id[0]}"
  port_id   = "${openstack_networking_port_v2.router.*.id[0]}"
}
