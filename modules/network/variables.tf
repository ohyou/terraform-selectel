# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

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
  description = "Private network config"
  type        = "map"

  default = {
    name    = "cloud.local"
    cidr    = "192.168.0.0/24"
    gateway = "192.168.0.1"
  }
}

variable "dns" {
  description = "List of name servers"
  type        = "list"

  default = [
    "1.1.1.1",
    "8.8.8.8",
  ]
}

variable "wan" {
  description = "Public network"
  type        = "map"

  default = {
    uuid  = ""
    name  = "external-network"
  }
}
