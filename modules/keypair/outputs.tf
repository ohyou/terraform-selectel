# Copyright 2018 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

output "name" {
  description = "Keypair name"
  value       = "${local.name}"
}

output "public" {
  description = "Public key"
  value       = "${data.tls_public_key.keypair.public_key_openssh}"
  sensitive   = true
}

output "private" {
  description = "Private key"
  value       = "${
    var.private == "" ?
    join("", tls_private_key.keypair.*.private_key_pem) :
    var.private
  }"
  sensitive   = true
}
