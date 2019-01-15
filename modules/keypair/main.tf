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
  name    = "${var.name == "" ? local.domain : var.name}"

  private = "${
    var.private_key == "" ? 
    join("", tls_private_key.keypair.*.private_key_pem) :
    var.private_key
  }"

  public  = "${
    var.private_key == "" ?
    join("", tls_private_key.keypair.*.public_key_openssh) :
    join("", data.tls_public_key.keypair.*.public_key_openssh) 
  }"
}

# -----------------------------------------------------------------------------
# Keypair.
# -----------------------------------------------------------------------------

resource "tls_private_key" "keypair" {
  count     = "${var.private_key == "" ? 1 : 0}"
  algorithm = "RSA"
  rsa_bits  = "2048"
}

data "tls_public_key" "keypair" {
  count           = "${var.private_key == "" ? 0 : 1}"
  private_key_pem = "${var.private_key}"
}

resource "openstack_compute_keypair_v2" "keypair" {
  region      = "${local.region}"
  name        = "${local.name}"
  public_key  = "${local.public}"
}