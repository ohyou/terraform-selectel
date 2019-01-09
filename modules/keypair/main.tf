# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

# -----------------------------------------------------------------------------
# Default parameters.
# -----------------------------------------------------------------------------

locals {
  domain  = "${lookup(var.cloud, "name", "cloud.local")}"
  region  = "${lookup(var.cloud, "region", "ru-1")}"
  name    = "${var.name == "" ? local.domain : var.name}"
}

# -----------------------------------------------------------------------------
# Keypair provisioning.
# -----------------------------------------------------------------------------

resource "tls_private_key" "keypair" {
  count     = "${var.private == "" ? 1 : 0}"
  algorithm = "RSA"
  rsa_bits  = "2048"
}

data "tls_public_key" "keypair" {
  private_key_pem = "${
    var.private == "" ?
    join("", tls_private_key.keypair.*.private_key_pem) :
    var.private
  }"
}

resource "openstack_compute_keypair_v2" "keypair" {
  region      = "${local.region}"
  name        = "${local.name}"
  public_key  = "${data.tls_public_key.keypair.public_key_openssh}"
}
