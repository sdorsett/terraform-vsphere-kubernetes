variable "vsphere_connection" {
  type                      = "map"
  description               = "Configuration details for connecting to vsphere"

  default = {
    # vsphere login account. defaults to administrator@vsphere.local account
    vsphere_user            = "administrator@vsphere.local"
    # vsphere account password. empty by default
    vsphere_password        = ""
    # vsphere server, defaults to localhost
    vsphere_server          = "localhost"
  } 
}

variable "virtual_machine_template" {
  type                      = "map"
  description               = "Configuration details for virtual machine template"

  default = {
    # name of the template to deploy from. empty by default
    name                    = ""
    # default connection_type to SSH
    connection_type         = "ssh"
    # username to connect to deployed virtual machines. defaults to "root"
    connection_user         = "root"
    # default password to initially connect to deployed virtual machines. empty by default
    connection_password     = ""
    # vsphere datacenter that the template is located in. empty by default
    datacenter = ""
  }
}

variable "virtual_machine_kubernetes_controller" {
  type                      = "map"
  description               = "Configuration details for kubernetes_controller virtual machine"

  default = {
    # name of the virtual machine to be deployed. defaults to "kubernetes-controller"
    name                    = "kubernetes-controller"
    # name of the datastore to deploy kubernetes_controller to. defaults to "datastore1"
    datastore               = "datastore1"
    # name of network to deploy kubernetes_controller to. defaults to "VM Network"
    network                 = "VM Network"
    # ip address to be assigned to kubernetes_controller. empty by default
    ip_address              = ""
    # netmask assigned to kubernetes_controller. defaults to "24"
    netmask                 = "24"
    # dns server assigned to kubernetes_controller. defaults to "8.8.8.8"
    dns_server              = "8.8.8.8"
    # default gateway to be assigned to kubernetes_controller. empty by default
    gateway                 = ""
    # resource pool to deploy kubernetes_controller to. empty by default
    resource_pool           = ""
    # private key to be used for SSH connections - this will be generated/overwritten on a terraform apply
    private_key = "/root/.ssh/id_rsa-terraform-vsphere-kubernetes"
    # public key to be copied to virtual machine
    public_key = "/root/.ssh/id_rsa-terraform-vsphere-kubernetes.pub"
    # number of vcpu assigned to kubernetes_controller. default is 2
    num_cpus = 2
    # amount of memory assigned to kubernetes_controller. default is 4096 (4GB)
    memory   = 4096
  }
}

