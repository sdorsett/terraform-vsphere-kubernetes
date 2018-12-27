provider "vsphere" {
  user           = "${var.vsphere_connection.["vsphere_user"]}"
  password       = "${var.vsphere_connection.["vsphere_password"]}"
  vsphere_server = "${var.vsphere_connection.["vsphere_server"]}"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "template_datacenter" {
  name = "${var.virtual_machine_template.["datacenter"]}"
}

data "vsphere_datastore" "vm_datastore" {
  name          = "${var.virtual_machine_kubernetes_controller.["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

data "vsphere_resource_pool" "vm_resource_pool" {
  name          = "${var.virtual_machine_kubernetes_controller.["resource_pool"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

data "vsphere_network" "vm_network" {
  name          = "${var.virtual_machine_kubernetes_controller.["network"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.virtual_machine_template.["name"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

resource "vsphere_virtual_machine" "kubernetes_controller" {
  name             = "${var.virtual_machine_kubernetes_controller.["name"]}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.vm_datastore.id}"

  num_cpus = "${var.virtual_machine_kubernetes_controller.["num_cpus"]}"
  memory   = "${var.virtual_machine_kubernetes_controller.["memory"]}"
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
        host_name = "${var.virtual_machine_kubernetes_controller.["name"]}"
        domain    = "kubernetes.local"
      }

      dns_server_list = ["${var.virtual_machine_kubernetes_controller.["dns_server"]}"]
      dns_suffix_list = ["kubernetes.local"]

      network_interface {
        ipv4_address = "${var.virtual_machine_kubernetes_controller.["ip_address"]}"
        ipv4_netmask = "${var.virtual_machine_kubernetes_controller.["netmask"]}"
      }

      ipv4_gateway = "${var.virtual_machine_kubernetes_controller.["gateway"]}"
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
      "sudo /tmp/kubeadm_init.sh",
      "tail -n2 /tmp/kubeadm_init_output.txt | head -n 1",
    ]
    connection {
      type          = "${var.virtual_machine_template.["connection_type"]}"
      user          = "${var.virtual_machine_template.["connection_user"]}"
      private_key   = "${file("${var.virtual_machine_kubernetes_controller.["private_key"]}")}" 
    }
  }

}
