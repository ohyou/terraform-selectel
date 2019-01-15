# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

variable "cloud" {
  description = "Cloud configuration"
  type        = "map"

  default = {
    name    = "cloud.local"
    region  = "ru-1"
    zone    = "ru-1a"
  }
}

variable "name" {
  description = "Instance name"
  type        = "string"
}

variable "keypair" {
  description = "Keypair name"
  type        = "string"
}

variable "number" {
  description = "The number of instance to create"
  type        = "string"

  default = 1
}

variable "lan" {
  description = "Instance private network configuration"
  type        = "map"

  default = {
    uuid    = ""
    name    = ""
    address = ""
  }
}

variable "wan" {
  description = "Instance public network configuration"
  type        = "map"

  default = {
    uuid    = ""
    name    = ""
    address = ""
  }
}

variable "flavor" {
  description = "Instance flavor configuration"
  type        = "map"

  default = {
    cpu = 2
    ram = 2048
  }
}

variable "disk" {
  description = "Instance system volume configuration"
  type        = "map"

  default = {
    name  = "root"
    size  = 5
    type  = "fast"
    image = "Centos 7 Minimal 64-bit"
  }
}

variable "tags" {
  description = "Instance metadata"
  type        = "map"

  default = {
    terraform = "yes"
  }
}
