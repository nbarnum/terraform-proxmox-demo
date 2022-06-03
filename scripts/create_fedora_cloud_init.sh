#!/bin/bash

set -e

# Create Fedora 33 cloud-init image in Proxmox

#### CONFIG ####

# specify which cloud image to use
FEDORA_CLOUD_IMAGE_URL="https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/33/Cloud/x86_64/images/"
FEDORA_CLOUD_IMAGE="Fedora-Cloud-Base-33-1.2.x86_64.qcow2"
# VM id and name to give the template
VM_ID="9003"
VM_NAME="fedora33"
# Linux Bridge network device to use
LINUX_BRIDGE="vmbr0"

#### CREATE TEMPLATE ####

# pull down cloud image
echo ">>> checking if cloudimg file already exists..."
if [ ! -f $FEDORA_CLOUD_IMAGE ]; then
    echo ">>> cloudimg file $FEDORA_CLOUD_IMAGE doesn't exist, pulling..."
    wget -q "${FEDORA_CLOUD_IMAGE_URL}${FEDORA_CLOUD_IMAGE}"
fi

# delete VM if it exists
if qm status $VM_ID >/dev/null; then
    echo ">>> VM id $VM_ID already exists, deleting..."
    qm destroy $VM_ID
fi

# create a new VM
echo ">>> creating VM $VM_ID..."
qm create $VM_ID --name $VM_NAME --memory 1024 --net0 virtio,bridge=${LINUX_BRIDGE}

# import the downloaded disk to local-lvm storage
echo ">>> importing disk..."
qm importdisk $VM_ID ${FEDORA_CLOUD_IMAGE} local-lvm

# finally attach the new disk to the VM as scsi drive
echo ">>> attaching disk to VM..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${VM_ID}-disk-0

# configure cdrom drive used to pass cloud-init data
echo ">>> configuring cloudinit..."
qm set $VM_ID --ide2 local-lvm:cloudinit

# restrict BIOS to boot from disk only (skip cdrom to speed up boot)
echo ">>> setting boot configuration..."
qm set $VM_ID --boot c --bootdisk scsi0

# configure serial console and use as display
echo ">>> configuring display..."
qm set $VM_ID --serial0 socket --vga serial0

# convert the VM into a template
echo ">>> converting to template..."
qm template $VM_ID

echo ">>> done"
