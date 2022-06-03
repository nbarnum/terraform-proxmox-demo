#!/bin/bash

set -e

# Create Ubuntu cloud-init image in Proxmox

#### CONFIG ####

# choose ubuntu cloud image version
#   Ubuntu 18.04 is "bionic"
#   Ubuntu 20.04 is "focal"
#   Ubuntu 22.04 is "jammy"
UBUNTU_VERSION="jammy"
# VM id to give the template
VM_ID="9001"
# Linux Bridge network device to use
LINUX_BRIDGE="vmbr0"

#### CREATE TEMPLATE ####

# pull down ubuntu cloud image
echo ">>> checking if cloudimg file already exists..."
if [ ! -f ${UBUNTU_VERSION}-server-cloudimg-amd64.img ]; then
    echo ">>> cloudimg file ${UBUNTU_VERSION}-server-cloudimg-amd64.img doesn't exist, pulling..."
    wget -q https://cloud-images.ubuntu.com/${UBUNTU_VERSION}/current/${UBUNTU_VERSION}-server-cloudimg-amd64.img
fi

# delete VM if it exists
if qm status $VM_ID >/dev/null; then
    echo ">>> VM id $VM_ID already exists, deleting..."
    qm destroy $VM_ID
fi

# create a new VM
echo ">>> creating VM $VM_ID..."
qm create $VM_ID --name ubuntu-${UBUNTU_VERSION} --memory 1024 --net0 virtio,bridge=${LINUX_BRIDGE}

# import the downloaded disk to local-lvm storage
echo ">>> importing disk..."
qm importdisk $VM_ID ${UBUNTU_VERSION}-server-cloudimg-amd64.img local-lvm

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
