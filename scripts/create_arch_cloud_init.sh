#!/bin/bash

set -e

# Create Arch cloud-init image in Proxmox

#### CONFIG ####

# specify which cloud image to use
ARCH_CLOUD_IMAGE_URL="https://mirror.pkgbuild.com/images/v20210401.18564/"
ARCH_CLOUD_IMAGE="Arch-Linux-x86_64-cloudimg-20210401.18564.qcow2"
# VM id and name to give the template
VM_ID="9004"
VM_NAME="arch"
# Linux Bridge network device to use
LINUX_BRIDGE="vmbr0"

#### CREATE TEMPLATE ####

# pull down cloud image
echo ">>> checking if cloudimg file already exists..."
if [ ! -f $ARCH_CLOUD_IMAGE ]; then
    echo ">>> cloudimg file $ARCH_CLOUD_IMAGE doesn't exist, pulling..."
    wget -q "${ARCH_CLOUD_IMAGE_URL}${ARCH_CLOUD_IMAGE}"
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
qm importdisk $VM_ID ${ARCH_CLOUD_IMAGE} local-lvm

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
# TODO: https://wiki.archlinux.org/index.php/working_with_the_serial_console
# echo ">>> configuring display..."
# qm set $VM_ID --serial0 socket --vga serial0

# convert the VM into a template
echo ">>> converting to template..."
qm template $VM_ID

echo ">>> done"
