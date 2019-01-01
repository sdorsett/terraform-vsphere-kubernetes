output "controller_ip" { 
   value = "${vsphere_virtual_machine.kubernetes_controller.*.default_ip_address}" 
}
output "node_ips" {
   value = "${vsphere_virtual_machine.kubernetes_nodes.*.default_ip_address}"
}
output "controller_vm-moref" {
   value = "${vsphere_virtual_machine.kubernetes_controller.moid}"
}
output "node_vm-morefs" {
   value = "${vsphere_virtual_machine.kubernetes_nodes.*.moid}"
}
output "kubeadm-init-info" {
   value = "${data.external.kubeadm-init-info.result}"
}

