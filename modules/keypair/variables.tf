# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

variable "cloud" {
  description = "Cloud config"
  type        = "map"

  default = {
    name    = "cloud.local"
    region  = "ru-1"
  }
}

variable "name" {
  description = "Keypair name"
  type        = "string"

  default = ""
}

variable "private" {
  description = "Private key"
  type        = "string"

  default = ""
}