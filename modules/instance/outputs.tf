# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

output "instance" {
  description = "Instance configuration"
  value       = [
    for i, v in openstack_compute_instance_v2.instance: {
      uuid  = "${v.id}"
      name  = "${v.name}"
      disk  = "${openstack_blockstorage_volume_v2.root.*.id[i]}"
      lan   = "${openstack_networking_port_v2.lan.*.all_fixed_ips[i][0]}"
      wan   = "${
        element(
          coalescelist(
            openstack_networking_floatingip_associate_v2.wan.*.floating_ip,
            flatten(openstack_networking_port_v2.wan.*.all_fixed_ips),
            [""]
          ),
          i
        )
      }"
    }
  ]

  depends_on  = [
    "openstack_compute_instance_v2.instance"
  ]
}
