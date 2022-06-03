#!/bin/bash

set -e

# Create CentOS 7 cloud-init image in Proxmox

#### CONFIG ####

# specify which cloud image to use
CENTOS_CLOUD_IMAGE_URL="https://cloud.centos.org/centos/7/images/"
CENTOS_CLOUD_IMAGE="CentOS-7-x86_64-GenericCloud-2009.qcow2"
# VM id and name to give the template
VM_ID="9001"
VM_NAME="centos7"
# Linux Bridge network device to use
LINUX_BRIDGE="vmbr0"

#### CREATE TEMPLATE ####

# pull down centos cloud image
echo ">>> checking if cloudimg file already exists..."
if [ ! -f $CENTOS_CLOUD_IMAGE ]; then
    echo ">>> cloudimg file $CENTOS_CLOUD_IMAGE doesn't exist, pulling..."
    wget -q "${CENTOS_CLOUD_IMAGE_URL}${CENTOS_CLOUD_IMAGE}"

    # address CentOS 7 cloud image ssh issues
    # https://gist.github.com/lukasnellen/c090b76984fe9b4552b919b6caf18092
    if ! which virt-sysprep &>/dev/null; then
        echo "ERROR: virt-sysprep not found, please install"
        echo "(libguestfs-tools on Debian/Ubuntu)"
        exit 1
    fi
    echo ">>> fixing /etc/resolv.conf and disabling GSSAPI in /etc/ssh/sshd_config..."
    virt-sysprep -a $CENTOS_CLOUD_IMAGE --delete '/etc/resolv.conf' --edit '/etc/ssh/sshd_config:s/^GSS/# GSS/'
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
qm importdisk $VM_ID ${CENTOS_CLOUD_IMAGE} local-lvm

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
