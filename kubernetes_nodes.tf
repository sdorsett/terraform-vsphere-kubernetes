data "vsphere_datastore" "node_datastore" {
  name          = "${var.virtual_machine_kubernetes_node.["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

data "vsphere_resource_pool" "node_resource_pool" {
  name          = "${var.virtual_machine_kubernetes_node.["resource_pool"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

data "vsphere_network" "node_network" {
  name          = "${var.virtual_machine_kubernetes_node.["network"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

resource "vsphere_virtual_machine" "kubernetes_nodes" {
  count            = "${var.virtual_machine_kubernetes_node.["count"]}"
  name             = "${format("${var.virtual_machine_kubernetes_node.["prefix"]}-%03d", count.index + 1)}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.vm_datastore.id}"

  num_cpus = "${var.virtual_machine_kubernetes_node.["num_cpus"]}"
  memory   = "${var.virtual_machine_kubernetes_node.["memory"]}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${format("${var.virtual_machine_kubernetes_node.["prefix"]}-%03d", count.index + 1)}"
        domain    = "kubernetes.local"
      }

      dns_server_list = ["${var.virtual_machine_kubernetes_node.["dns_server"]}"]
      dns_suffix_list = ["kubernetes.local"]

      network_interface {
        ipv4_address = "${cidrhost( var.virtual_machine_kubernetes_node.["ip_address_network"], var.virtual_machine_kubernetes_node.["starting_hostnum"]+count.index )}"
        ipv4_netmask = "${element( split("/", var.virtual_machine_kubernetes_node.["ip_address_network"]), 1)}"
      }

      ipv4_gateway = "${var.virtual_machine_kubernetes_node.["gateway"]}"
    }
  }

  provisioner "file" {
    source      = "${var.virtual_machine_kubernetes_controller.["public_key"]}"
    destination = "/tmp/authorized_keys"

    connection {
      type        = "${var.virtual_machine_template.["connection_type"]}"
      user        = "${var.virtual_machine_template.["connection_user"]}"
      password    = "${var.virtual_machine_template.["connection_password"]}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh/",
      "chmod 700 /root/.ssh",
      "mv /tmp/authorized_keys /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config", 
      "service sshd restart" 
    ]
    connection {
      type          = "${var.virtual_machine_template.["connection_type"]}"
      user          = "${var.virtual_machine_template.["connection_user"]}"
      password      = "${var.virtual_machine_template.["connection_password"]}"
    }
  }

  provisioner "file" {
    source      = "./scripts/"
    destination = "/tmp/"

    connection {
      type        = "${var.virtual_machine_template.["connection_type"]}"
      user        = "${var.virtual_machine_template.["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller.["private_key"]}")}" 
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/*sh",
      "sudo /tmp/system_setup.sh",
      "sudo /tmp/install_docker.sh",
      "sudo /tmp/install_kubernetes_packages.sh",
    ]
    connection {
      type          = "${var.virtual_machine_template.["connection_type"]}"
      user          = "${var.virtual_machine_template.["connection_user"]}"
      private_key   = "${file("${var.virtual_machine_kubernetes_controller.["private_key"]}")}" 
    }
  }

}

resource "null_resource" "kubeadm_join" {
  count            = "${var.virtual_machine_kubernetes_node.["count"]}"
  provisioner "remote-exec" {
    inline = [
       "kubeadm join --token ${data.external.kubeadm-init-info.result.token} ${vsphere_virtual_machine.kubernetes_controller.0.default_ip_address}:6443 --discovery-token-ca-cert-hash sha256:${data.external.kubeadm-init-info.result.certhash}",
    ]
    connection {
      type          = "${var.virtual_machine_template.["connection_type"]}"
      user          = "${var.virtual_machine_template.["connection_user"]}"
      private_key   = "${file("${var.virtual_machine_kubernetes_controller.["private_key"]}")}"
      host          = "${element(vsphere_virtual_machine.kubernetes_nodes.*.default_ip_address, count.index)}" 
    }
  }
}
