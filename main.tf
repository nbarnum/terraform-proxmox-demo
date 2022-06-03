terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.10"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://${var.target_node}:8006/api2/json"
  # disable TLS validation for self-signed proxmox certs
  pm_tls_insecure = true
  pm_parallel     = 1
}

# References:
#   - https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/vm_qemu
#   - https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md
resource "proxmox_vm_qemu" "vms" {
  # iterate over each VM defined in the "vm_defintions" in variables.tf
  for_each = var.vm_defintions

  # proxmox server to deploy VM onto
  target_node = each.value.target_node

  # VMs numeric ID
  vmid = each.value.vmid

  # one of: ubuntu, centos, cloud-init
  os_type = "cloud-init"

  # "l24" for Linux 2.4 kernel, "l26" for Linux 2.6 - 5.x kernel
  qemu_os = "l26"

  # template to clone
  clone = each.value.clone

  # whether to use a linked clone
  full_clone = true

  # whether to startup VM after creation
  oncreate = true

  # whether to startup the VM after PVE reboot
  onboot = true

  # Cloud-Init > DNS servers
  nameserver = var.nameservers
  # Cloud-Init > DNS domain
  searchdomain = var.searchdomain
  # Cloud-Init > SSH public key
  sshkeys = var.sshkeys
  # Cloud-Init > IP Config (net0)
  ipconfig0 = each.value.ipconfig0

  # Options > Name
  name = each.key

  # Options > QEMU Guest Agent (0=disabled, 1=enabled)
  # FIXME: terraform apply will hang when creating new VMs if qemu-guest-agent is enabled but
  # service is not installed and running.
  # Need to either install guest agent via cloud-init data or build a custom image to enable this.
  agent = 0

  # Hardware > Memory
  memory = each.value.memory
  # Hardware > Processors > Cores
  cores = each.value.cores

  # Hardware > Hard Disk (scsi0)
  disk {
    type    = "scsi"
    storage = each.value.disk_storage
    size    = each.value.disk_size
  }

  # Hardware > Network Device (net0)
  network {
    bridge = each.value.network_bridge
    model  = "virtio"
  }
}
