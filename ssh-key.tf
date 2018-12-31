resource "null_resource" "generate-sshkey" {
    provisioner "local-exec" {
        command = "yes y | ssh-keygen -b 4096 -t rsa -C 'terraform-vsphere-kubernetes' -N '' -f ${var.virtual_machine_kubernetes_controller.["private_key"]}"
    }
}

resource "null_resource" "ssh-keygen-delete" {
    provisioner "local-exec" {
        command = "ssh-keygen -R ${var.virtual_machine_kubernetes_controller.["ip_address"]}"
    }
}
