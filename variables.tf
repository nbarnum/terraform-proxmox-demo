variable "vm_defintions" {
  description = "Map of settings that are looped to define virtual machines"
  type        = map(any)

  # TODO: define VMs to deploy
  default = {
    vm01 = {
      # template to clone
      clone = "ubuntu-focal"
      # number of CPU cores
      cores = 1
      # size of root partition
      disk_size = "10G"
      # match name of storage on target PVE node
      disk_storage = "ssd1"
      # IP address, subnet mask, and gateway
      ipconfig0 = "ip=172.20.2.21/22,gw=172.20.0.1"
      # MiB of RAM to assign
      memory = 1024
      # network bridge to use
      network_bridge = "vmbr0"
      # which PVE node to assign VM
      target_node = "pve01"
      # numeric VM ID
      vmid = 2021
    },
    vm02 = {
      clone          = "ubuntu-focal"
      cores          = 2
      disk_size      = "10G"
      disk_storage   = "ssd1"
      ipconfig0      = "ip=172.20.2.22/22,gw=172.20.0.1"
      memory         = 2048
      network_bridge = "vmbr0"
      target_node    = "pve02"
      vmid           = 2022
    },
  }
}

variable "sshkeys" {
  description = "SSH public key installed on VMs under default user (i.e. ubuntu user for Ubuntu cloud images)"
  type        = string

  # TODO: replace value with your SSH public key
  default = "INSERT_YOUR_PUBLIC_KEY_HERE"
}

variable "target_node" {
  description = "Hostname or IP for terraform to contact for API calls"
  type        = string

  # TODO: insert proxmox node's IP or hostname
  default = "pve01.localdomain"
}

variable "nameservers" {
  description = "DNS nameservers assigned to VMs"
  type        = string

  # TODO: insert DNS nameserver addresses for VMs to use
  default = "172.20.2.53"
}

variable "searchdomain" {
  description = "DNS search domain assigned to VMs"
  type        = string

  # TODO: insert DNS search domain for VMs to use
  default = "localdomain"
}
