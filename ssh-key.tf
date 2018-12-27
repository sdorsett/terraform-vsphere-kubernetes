resource "null_resource" "generate-sshkey" {
    provisioner "local-exec" {
        command = "yes y | ssh-keygen -b 4096 -t rsa -C 'terraform-vsphere-kubernetes' -N '' -f ${var.virtual_machine_kubernetes_controller.["private_key"]}"
    }
}
