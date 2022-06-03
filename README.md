# terraform-proxmox-demo

Example of using [Terraform](https://www.terraform.io/) to provision virtual machines using [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) (referred to as `PVE` for the remainder of this README).

References:

- [Telmate proxmox terraform provider docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

## Prerequisites

- Running PVE hypervisor(s) (works with clustered PVE hosts)
- SSH access to PVE host
- Terraform cli installed

## Usage

1. Copy the `create_ubuntu_cloud_init.sh` script to a PVE host, using `172.20.1.21` in this example

    ```shell
    $ scp scripts/create_ubuntu_cloud_init.sh root@172.20.1.21:~/
    ```

2. Run the `create_ubuntu_cloud_init.sh` script to create an Ubuntu VM template

    Review the script, making needed changes for your environment (i.e. changing the default Ubuntu version).

    ```shell
    $ ssh root@172.20.1.21
    root@pve01:~# ./create_ubuntu_cloud_init.sh
    ```

3. Login to the PVE admin UI and confirm the VM template was created as expected

4. Back on your local machine, export environment variables for PVE username and password

    Replace this username and password with your PVE creds:

    ```shell
    $ export PM_USER='root@pam'
    $ export PM_PASS='supersecretpassword'
    ```

5. Initialize the proxmox terraform provider

    ```shell
    $ terraform init

    Initializing the backend...

    Initializing provider plugins...
    - Finding telmate/proxmox versions matching "2.9.10"...
    - Installing telmate/proxmox v2.9.10...

    ...
    ```

6. Update variables in the `variables.tf` file

    Review all variables and makes sure to match them to your environment. Search for `TODO:` to make identifying needed updates easier.

    Example VM config:

    ```hcl
    myvm = {
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
    ```

7. Review and apply changes

    ```shell
    $ terraform apply
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # proxmox_vm_qemu.vms["myvm"] will be created
      + resource "proxmox_vm_qemu" "vms" {
      ...
      }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value: yes

    proxmox_vm_qemu.vms["myvm"]: Creating...
    proxmox_vm_qemu.vms["myvm"]: Still creating... [10s elapsed]
    proxmox_vm_qemu.vms["myvm"]: Still creating... [20s elapsed]
    ...
    proxmox_vm_qemu.vms["myvm"]: Still creating... [2m10s elapsed]
    proxmox_vm_qemu.vms["myvm"]: Creation complete after 2m12s [id=pve02/qemu/2022]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```

8. If all went well, a VM should be created on the targeted PVE host

    You should now be able to ssh to the VM using the default `ubuntu` username and the IP specified in the VM configuration (172.20.2.22 in my example).

    ```shell
    $ ssh ubuntu@172.20.2.22
    Welcome to Ubuntu 22.04 LTS (GNU/Linux 5.15.0-33-generic x86_64)
    ...

    ubuntu@myvm:~$ sudo -l
    Matching Defaults entries for ubuntu on myvm:
        env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty

    User ubuntu may run the following commands on myvm:
        (ALL : ALL) ALL
        (ALL) NOPASSWD: ALL
    ```
