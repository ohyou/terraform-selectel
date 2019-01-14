# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

output "name" {
  description = "Keypair name"
  value       = "${local.name}"
}

output "public_key" {
  description = "Public key"
  sensitive   = true
  value       = "${local.public}"
}

output "private_key" {
  description = "Private key"
  sensitive   = true
  value       = "${local.private}"
}
