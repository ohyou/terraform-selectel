# Copyright 2019 Kodix LLC. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

data "null_data_source" "instance" {
  count = "${var.count}"

  inputs {
    uuid  = "${
      element(coalescelist(
        openstack_compute_instance_v2.wan.*.id,
        openstack_compute_instance_v2.lan.*.id
      ), count.index)
    }"
    name  = "${
      element(coalescelist(
        openstack_compute_instance_v2.wan.*.name,
        openstack_compute_instance_v2.lan.*.name
      ), count.index)
    }"
    disk  = "${openstack_blockstorage_volume_v2.root.*.id[count.index]}"
    lan   = "${element(openstack_networking_port_v2.lan.*.all_fixed_ips[count.index], 0)}"
    wan   = "${
      element(coalescelist(
        openstack_networking_floatingip_associate_v2.wan.*.floating_ip,
        flatten(openstack_networking_port_v2.wan.*.all_fixed_ips),
        list("")
      ), count.index)
    }"
  }
}

output "instance" {
  description = "Instance information"
  value       = "${data.null_data_source.instance.*.inputs}"
}
