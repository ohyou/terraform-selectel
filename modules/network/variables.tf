# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

variable "cloud" {
  description = "Cloud configuration"
  type        = "map"

  default = {
    name    = "cloud.local"
    region  = "ru-1"
  }
}

variable "lan" {
  description = "Private network configuration"
  type        = "map"

  default = {
    name    = ""
    cidr    = "192.168.0.0/24"
    gateway = ""
  }
}

variable "wan" {
  description = "Public network configuration"
  type        = "map"

  default = {
    uuid  = ""
    name  = "external-network"
  }
}

variable "dns" {
  description = "List of the name servers"
  type        = list(string)

  default = [
    "1.1.1.1",
    "8.8.8.8",
  ]
}

variable "pool" {
  description = "List of private network address pools"
  type        = list(object({
    start = string
    end   = string
  }))

  default = []
}
