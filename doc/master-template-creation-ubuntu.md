# Ubuntu 22.04 Master Template

**_DO NOT USE THIS TEMPLATE TO CREATE NEW VIRTUAL MACHINES. USE THE `UBUNTU2204-TEMPLATE` IMAGE_**

## Base Image Creation

### Convert .qcow2 to .img

After downloading the stock image, convert it from `qcow2` format to `raw` (`img`) format using
`qemu-img convert -f qcow2 -O raw <image_name>.qcow2 /mnt/pve/cephfs/template/iso/<image_name>.img`

This will drop the new .img file into the Proxmox ISO Template directory

```bash
qemu-img convert -f qcow2 -O raw AlmaLinux-9-GenericCloud-9.3.x86_64.qcow2 /mnt/pve/cephfs/template/iso/AlmaLinux-9-GenericCloud-9.3.x86_64.img
```

- Set a variable `image_name` to the full path of the .img file

Examples

```bash
export image_name=/mnt/pve/cephfs/template/iso/Rocky-9-GenericCloud-9.3.x86_64.img
export image_name=/mnt/pve/cephfs/template/iso/AlmaLinux-9-GenericCloud-9.3.x86_64.img
export image_name=/mnt/pve/cephfs/template/iso/CentOS-9-Stream-GenericCloud-latest.x86_64.img
export image_name=/mnt/pve/cephfs/template/iso/Ubuntu-22.04-GenericCloud-latest.x86_64.img
```

You will use this variable in the following steps.

- Convert the cow image to raw

### Image/Template Modifications

The base image has been directly modified using [libguestfs-tools](https://libguestfs.org)

Configuration examples and reference can be found at
[Proxmox Cloud-Init OS Template Creation](https://whattheserver.com/proxmox-cloud-init-os-template-creation)

- Data mount: systemd service created and enabled for data.mount
- Media mount: systemd service created and enabled for media.mount
- Root Password: default root password updated
- Root Authorized Keys: default root ssh keys added
- SSHD Configurations: root login enabled, password login enabled, authorized keys enabled
- Qemu Guest Agent: guest-agent package installed, guest-agent service enabled

#### Commands

**_Note: The root password and SSH commands do not need to be modified in the base image. Assuming
we are using cloud-init, these changes can be created in the VM's 'cloud-init' section. The
cloud-init disk and configurations will be stored with the template and passed along to cloned
VMs._**

- Run the following commands to perform a base-level customization on the image and prepare it for
  further configuration with Ansible.

```bash
virt-customize -a ${image_name} --root-password 'password:tmpRootPass' \
&& virt-edit -a ${image_name} /etc/shadow -e 's/^(root:)[^:]*(:.*)$/\1\$6\$rounds=1000\$HCNyXQ6pNitiYNKK\$hrAhlRSl7EgEuIhNF0msAe1vLnZ1fxeyAeCDLzJDEioPFr.AEpr4GijiFKsxIolBiQKOyu3jdFIKrooGHQfEN0\2/' \
&& virt-customize -a ${image_name} --run-command 'mkdir -p /root/.ssh' \
&& virt-customize -a ${image_name} --run-command 'touch /root/.ssh/authorized_keys' \
&& virt-customize -a ${image_name} --copy-in '/etc/systemd/system/data.mount:/etc/systemd/system/' \
&& virt-customize -a ${image_name} --copy-in '/etc/systemd/system/media.mount:/etc/systemd/system/' \
&& virt-customize -a ${image_name} --run-command 'systemctl daemon-reload' \
&& virt-customize -a ${image_name} --run-command 'systemctl enable data.mount' \
&& virt-customize -a ${image_name} --run-command 'systemctl enable media.mount' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/disable_root: [Tt]rue/disable_root: False/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/disable_root: 1/disable_root: 0/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/lock_passwd: [Tt]rue/lock_passwd: False/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/lock_passwd: 1/lock_passwd: 0/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/ssh_pwauth: [Ff]alse/ssh_pwauth: True/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/ssh_pwauth: 0/ssh_pwauth: 1/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/false/False/' \
&& virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/true/True/'
```

## Create VM and customize further

Next we will build create a VM from the configured .img file

### VM Creation from Image

- Using the Proxmox API, get the next available VMID and set a variable `guest_id` for later use

```bash
export guest_id=$(pvesh get /cluster/nextid) \
&& echo "guest_id: ${guest_id}"
```

- Also set a variable `vm_name` with the format of `distroN-template`for the VM name (which will
  become the template name)

Examples:

```bash
# export vm_name=ubuntu2204-template
# export vm_name=centos8-template
export vm_name=alma9-template \
&& echo "vm_name: ${vm_name}"
```

- Create a virtual machine with the customized raw image imported as the primary disk. This command
  also sets a number of options that we want for our template.

```bash
qm create ${guest_id} --name ${vm_name} --start 1 \
--cpu 'host,flags=+md-clear;+pcid;+spec-ctrl;+ssbd;+pdpe1gb;+aes' --cores 1 --sockets 2 --vcpus 2 \
--ostype l26 --tags 'kvm;telegraf;alma9' --pool Templates \
--memory 2048 --numa 1 --balloon 0 \
--scsihw virtio-scsi-single --boot 'order=scsi0;net0' --vmstatestorage ceph-rbd \
--hotplug disk,network,usb,memory,cpu,cloudinit --agent 1,fstrim_cloned_disks=1 \
--net0 virtio,bridge=vmbr0,mtu=1,queues=2 --ipconfig0 ip=10.0.10.10/24,gw=10.0.10.1 \
--scsi0 ceph-rbd:0,import-from=${image_name},backup=0,discard=on,replicate=0,ssd=1,iothread=1 \
--scsi1 ceph-rbd:cloudinit,media=cdrom \
--ciuser root --sshkeys '/root/.ssh/authorized_keys_master' \
--cipassword "${vm_password}"
```

A new virtual machine is created and the newly modified base image is imported to it's primary boot
disk `scsi0`.

### Run Ansible against the newly created VM

With the Proxmox inventory configured, we should be able to connect to the VM by hostname and it
should be in all of the necessary groups because of the tags we added on creation.

```bash
ansible-playbook playbooks/base.yml -l <vm_name>
```

## Create Template

- Shut down the VM

```bash
until qm shutdown ${guest_id}; do
echo "waiting for shutdown..."
done
```

- Reset the IP to DHCP

```bash
until qm set ${guest_id} --ipconfig0 ip=dhcp; do
echo "reconfiguring ${guest_id} with dhcp..."
done
```

- Convert to Template

```bash
until qm template ${guest_id}; do
echo "converting to template..."
done
```
