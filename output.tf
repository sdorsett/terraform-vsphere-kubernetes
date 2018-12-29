output "ip" { 
   value = "${vsphere_virtual_machine.kubernetes_controller.*.default_ip_address}" 
}
output "vm-moref" {
   value = "${vsphere_virtual_machine.kubernetes_controller.moid}"
}
output "kubeadm-init-info" {
   value = "${data.external.kubeadm-init-info.result}"
}

