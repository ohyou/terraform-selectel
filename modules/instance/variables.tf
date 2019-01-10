# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

variable "name" {
  description = "Instance name"
  type        = "string"
}

variable "count" {
  description = "The number of instances to create"
  type        = "string"

  default = 1
}

variable "cloud" {
  description = "Cloud config"
  type        = "map"

  default = {
    name    = "cloud.local"
    region  = "ru-1"
    zone    = "ru-1a"
  }
}

variable "lan" {
  description = "Private network"
  type        = "map"

  default = {
    uuid    = ""
    name    = ""
    address = ""
  }
}

variable "wan" {
  description = "Public network"
  type        = "map"

  default = {
    uuid    = ""
    name    = ""
    address = ""
  }
}

variable "flavor" {
  description = "Instance flavor config"
  type        = "map"

  default = {
    cpu   = 2
    ram   = 2048
  }
}

variable "disk" {
  description = "System volume config"
  type        = "map"

  default = {
    name    = "root"
    size    = 5
    type    = "fast"
    images  = "Centos 7 Minimal 64-bit"
  }
}

variable "metadata" {
  description = "Metadata key/value pairs"
  type        = "map"

  default = {
    terraform = "yes"
  }
}

variable "keypair" {
  description = "Keypair name"
  type        = "string"
}
