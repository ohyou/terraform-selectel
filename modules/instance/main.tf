# Copyright 2019 Kodix LLC. All rights reserved.
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
    "uuid",     "${lookup(var.lan, "uuid", "")}",
    "name",     "${lookup(var.lan, "name", "")}",
    "address",  "${lookup(var.lan, "address", "")}",
  )}"

  wan = "${map(
    "uuid",     "${lookup(var.wan, "uuid", "")}",
    "name",     "${lookup(var.wan, "name", "")}",
    "address",  "${lookup(var.wan, "address", "")}",
  )}"

  disk  = "${map(
    "name",   "${lookup(var.disk, "name", "root")}",
    "size",   "${lookup(var.disk, "size", 5)}",
    "type",   "${lookup(var.disk, "type", "fast")}",
    "image",  "${lookup(var.disk, "image", "Fedora 28 64-bit")}",
  )}"

  flavor = "${map(
    "name", "${var.name}",
    "cpu",  "${lookup(var.flavor, "cpu", 2)}",
    "ram",  "${lookup(var.flavor, "ram", 2048)}",
  )}"

  has_wan   = "${local.wan["uuid"] != "" || local.wan["name"] != ""}"
  external  = "${element(
    coalescelist(
      data.openstack_networking_network_v2.wan.*.external,
      list("false"),
    ), 
    1
  )}"
}

# -----------------------------------------------------------------------------
# Private network provisioning.
# -----------------------------------------------------------------------------

data "openstack_networking_network_v2" "lan" {
  region      = "${local.region}"
  name        = "${local.lan["name"]}"
  network_id  = "${local.lan["uuid"]}"
  external    = false
}

data "openstack_networking_subnet_v2" "lan" {
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.lan.id}"
}

resource "openstack_networking_port_v2" "lan" {
  count           = "${var.count}"
  name            = "${
    var.count > 1 ?
    "${var.name}-${count.index+1}.${local.domain}" :
    "${var.name}.${local.domain}"
  }"
  region          = "${local.region}"
  network_id      = "${data.openstack_networking_network_v2.lan.id}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${data.openstack_networking_subnet_v2.lan.id}"
    ip_address  = "${local.lan["address"]}"
  }
}

# -----------------------------------------------------------------------------
# Public network provisioning.
# -----------------------------------------------------------------------------

data "openstack_networking_network_v2" "wan" {
  count       = "${local.has_wan ? 1 : 0}"
  region      = "${local.region}"
  name        = "${local.wan["name"]}"
  network_id  = "${local.wan["uuid"]}"
}

data "openstack_networking_subnet_v2" "wan" {
  count       = "${local.has_wan && !local.external ? 1 : 0}"
  region      = "${local.region}"
  network_id  = "${data.openstack_networking_network_v2.wan.id}"
}

resource "openstack_networking_port_v2" "wan" {
  count           = "${local.has_wan && !local.external ? var.count : 0}"
  region          = "${local.region}"
  name            = "${var.name}.${local.domain}"
  network_id      = "${data.openstack_networking_network_v2.wan.id}"
  admin_state_up  = true

  fixed_ip {
    subnet_id   = "${data.openstack_networking_subnet_v2.wan.id}"
    ip_address  = "${local.wan["address"]}"
  }
}

resource "openstack_compute_interface_attach_v2" "wan" {
  count       = "${local.has_wan && !local.external ? var.count : 0}"
  instance_id = "${openstack_compute_instance_v2.instance.*.id[count.index]}"
  port_id     = "${openstack_networking_port_v2.wan.*.id[count.index]}"
}

resource "openstack_networking_floatingip_v2" "wan" {
  count = "${
    local.has_wan && local.external && local.wan["address"] == "" ?
    var.count :
    0
  }"
  pool  = "${data.openstack_networking_network_v2.wan.name}"
}

resource "openstack_networking_floatingip_associate_v2" "wan" {
  count       = "${local.has_wan && local.external ? var.count: 0}"
  region      = "${local.region}"
  floating_ip = "${
    local.wan["address"] == "" ? 
    openstack_networking_floatingip_v2.wan.*.address[count.index] :
    local.wan["address"]
  }"
  port_id     = "${openstack_networking_port_v2.lan.*.id[count.index]}"
}

# -----------------------------------------------------------------------------
# Instance provisioning.
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
  count             = "${var.count}"
  region            = "${local.region}"
  availability_zone = "${local.zone}"
  name              = "${
    var.count > 1 ?
    "${local.disk["name"]} for ${var.name}-${count.index+1}.${local.domain}" :
    "${local.disk["name"]} for ${var.name}.${local.domain}"
  }"
  size              = "${local.disk["size"]}"
  volume_type       = "${local.disk["type"]}.${local.zone}"
  image_id          = "${data.openstack_images_image_v2.system.id}"
}

resource "openstack_compute_instance_v2" "instance" {
  count               = "${var.count}"
  region              = "${local.region}"
  availability_zone   = "${local.zone}"
  name                = "${
    var.count > 1 ?
    "${var.name}-${count.index+1}.${local.domain}" :
    "${var.name}.${local.domain}"
  }"
  flavor_id           = "${openstack_compute_flavor_v2.instance.id}"
  key_pair            = "${var.keypair}"
  power_state         = "active"
  stop_before_destroy = true

  metadata = "${var.metadata}"

  block_device {
    uuid              = "${openstack_blockstorage_volume_v2.root.*.id[count.index]}"
    source_type       = "volume"
    destination_type  = "volume"
    boot_index        = 0
  }

  network {
    port  = "${openstack_networking_port_v2.lan.*.id[count.index]}" 
  }

  vendor_options {
    ignore_resize_confirmation = true
  }
}
