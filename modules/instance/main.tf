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
# Defaults.
# -----------------------------------------------------------------------------

locals {
  count   = "${var.number}"
  domain  = "${lookup(var.cloud, "name", "cloud.local")}"
  region  = "${lookup(var.cloud, "region", "ru-1")}"
  zone    = "${lookup(var.cloud, "zone", "${local.region}a")}"

  lan = {
    uuid    = "${lookup(var.lan, "uuid", "")}"
    name    = "${lookup(var.lan, "name", "")}"
    address = "${lookup(var.lan, "address", "")}"
  }

  wan = {
    uuid    = "${lookup(var.wan, "uuid", "")}"
    name    = "${lookup(var.wan, "name", "")}"
    address = "${lookup(var.wan, "address", "")}"
  }

  flavor = {
    name  = "${var.name}"
    cpu   = "${lookup(var.flavor, "cpu", 2)}"
    ram   = "${lookup(var.flavor, "ram", 2048)}"
  }

  disk = {
    name  = "${lookup(var.disk, "name", "root")}"
    size  = "${lookup(var.disk, "size", 5)}"
    type  = "${lookup(var.disk, "type", "fast")}"
    image = "${lookup(var.disk, "image", "Centos 7 Minimal 64-bit")}"
  }

  has_wan = "${local.wan["uuid"] != "" || local.wan["name"] != ""}"
  floating = "${
    local.has_wan && 
    element(
      coalescelist(
        data.openstack_networking_network_v2.wan.*.external, 
        [false]
      ), 
      0
    )
  }"
}

# -----------------------------------------------------------------------------
# Private network.
# -----------------------------------------------------------------------------

data "openstack_networking_network_v2" "lan" {
  region      = "${local.region}"
  name        = "${local.lan["name"]}"
  network_id  = "${local.lan["uuid"]}"
}

data "openstack_networking_subnet_v2" "lan" {
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.lan.id}"
}

resource "openstack_networking_port_v2" "lan" {
  count           = "${local.count}"
  name            = "${
    local.count > 1 ?
    "${var.name}-${count.index+1}.${local.domain}" :
    "${var.name}.${local.domain}"
  }"
  network_id      = "${data.openstack_networking_network_v2.lan.id}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${data.openstack_networking_subnet_v2.lan.id}"
    ip_address  = "${local.lan["address"]}"
  }

  depends_on = [
    "data.openstack_networking_subnet_v2.lan"
  ]
}

# -----------------------------------------------------------------------------
# Public network.
# -----------------------------------------------------------------------------

data "openstack_networking_network_v2" "wan" {
  count       = "${local.has_wan ? 1 : 0}"
  region      = "${local.region}"
  name        = "${local.wan["name"]}"
  network_id  = "${local.wan["uuid"]}"
}

data "openstack_networking_subnet_v2" "wan" {
  count       = "${local.has_wan && !local.floating ? 1 : 0}"
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.wan.*.id[0]}"
}

resource "openstack_networking_floatingip_v2" "wan" {
  count   = "${
    local.has_wan && local.floating && local.wan["address"] == "" ?
    local.count :
    0
  }"
  region  = "${local.region}"
  pool    = "${data.openstack_networking_network_v2.wan.*.name[0]}"
}

resource "openstack_networking_floatingip_associate_v2" "wan" {
  count       = "${local.has_wan && local.floating ? local.count : 0}"
  region      = "${local.region}"
  floating_ip = "${
    local.wan["address"] == "" ?
    openstack_networking_floatingip_v2.wan.*.address[count.index] :
    local.wan["address"]
  }"
  port_id     = "${openstack_networking_port_v2.lan.*.id[count.index]}"
}

resource "openstack_networking_port_v2" "wan" {
  count           = "${local.has_wan && !local.floating ? local.count : 0}"
  region          = "${local.region}"
  name            = "${var.name}.${local.domain}"
  network_id      = "${data.openstack_networking_network_v2.wan.*.id[0]}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${data.openstack_networking_subnet_v2.wan.*.id[0]}"
    ip_address  = "${local.wan["address"]}"
  }

  depends_on = [
    "data.openstack_networking_subnet_v2.wan"
  ]
}

# -----------------------------------------------------------------------------
# Instance.
# -----------------------------------------------------------------------------

resource "openstack_compute_flavor_v2" "instance" {
  region  = "${local.region}"
  name    = "${local.flavor["name"]}.${local.domain}"
  vcpus   = "${local.flavor["cpu"]}"
  ram     = "${local.flavor["ram"]}"
  disk    = 0
  swap    = 0
}

data "openstack_images_image_v2" "system" {
  region  = "${local.region}"
  name    = "${local.disk["image"]}"
}

resource "openstack_blockstorage_volume_v2" "root" {
  count             = "${local.count}"
  region            = "${local.region}"
  availability_zone = "${local.zone}"
  name              = "${
    local.count > 1 ?
    "${local.disk["name"]} for ${var.name}-${count.index+1}.${local.domain}" :
    "${local.disk["name"]} for ${var.name}.${local.domain}"
  }"
  size              = "${local.disk["size"]}"
  volume_type       = "${local.disk["type"]}.${local.zone}"
  image_id          = "${data.openstack_images_image_v2.system.id}"
}

resource "openstack_compute_instance_v2" "instance" {
  count               = "${local.count}"
  region              = "${local.region}"
  availability_zone   = "${local.zone}"
  name                = "${
    local.count > 1 ? 
    "${var.name}-${count.index+1}.${local.domain}" :
    "${var.name}.${local.domain}"
  }"
  flavor_id           = "${openstack_compute_flavor_v2.instance.id}"
  key_pair            = "${var.keypair}"
  power_state         = "active"
  stop_before_destroy = true
  metadata            = "${var.tags}"

  block_device {
    uuid              = "${openstack_blockstorage_volume_v2.root.*.id[count.index]}"
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
  }

  dynamic "network" {
    for_each  = "${
      local.has_wan && !local.floating ?
      [
        openstack_networking_port_v2.wan.*.id[count.index],
        openstack_networking_port_v2.lan.*.id[count.index]
      ] :
      [openstack_networking_port_v2.lan.*.id[count.index]]
    }"

    content {
      port  = "${network.value}"
    }
  }

  vendor_options {
    ignore_resize_confirmation = true
  }

  depends_on = [
    "openstack_networking_port_v2.wan",
    "openstack_networking_port_v2.lan"
  ]
}
