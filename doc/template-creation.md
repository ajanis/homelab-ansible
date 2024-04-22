# Ubuntu 22.04 LXC Template

This template was created from the stock `Ubuntu 22.04 LXC Template`

## Create Fully-Configured Ubuntu 22.04 LXC Container by cloning this template

Container template includes systemd services for `/data` and `/media` CephFS mounts, LDAP
authentication, CephFS `$HOME` directory mounting via AutoFS and LDAP, and standard
packages/configurations from ansible `common` role

- Right click on the ``ubuntu2204-lxc-template` in the Datacenter View pane
- Click the Clone option from the context menu
- Select Full Clone from the dropdown box
- Enter Name and PVE Host
- Click Clone button

### Further custommization

Per usual…

- Add host-specific configurations to Ansible (playbook, inventory, etc.) and run against the cloned
  container.
- Enjoy..

## LXC Template Creation

The following section covers how to create a custom LXC Template from a stock
`Ubuntu 22.04 Template`

### Base specifications for the `template-container`

```
arch: amd64
cores: 2
features: mount=ceph;autofs;nfs
hostname: ubuntu-lxc-template
memory: 4096
mp0: ceph-rbd:vm-114-disk-1,mp=/opt,size=15G
net0: name=eth0,bridge=vmbr0,firewall=1,hwaddr=0E:F9:91:40:F3:66,ip=dhcp,mtu=9000,type=veth
ostype: ubuntu
rootfs: ceph-rbd:vm-114-disk-0,replicate=0,size=10G
swap: 512
```

### Customization Steps

- Add root password and SSH authorized keys in GUI

  _Note: You can get the current authorized_keys from one of the KVM Template’s `cloud-init` config
  section._

- Add Ceph RBD disk mount-point at /opt in GUI

  - Device: mp0
  - Type: ceph-rbd
  - Mount: /opt
  - Size: 15G

- Enable Ceph and AutoFS Mounts via CLI

  _Note: This must be done from the PVE node where the container is running._

  ```
  pct set <id> -features 'mount=ceph;autofs;nfs’
  ```

- Update container OS/Packages

  ```
  apt-get update
  apt-get upgrade
  ```

- Run Ansible Configuration

  - Add LXC Container to Ansible inventory under `common`

  ```
  all:
    children:
      common:
        hosts:
          ubuntu-lxc-template.home.prettybaked.com:
            ansible_ssh_host: 10.0.10.221
  ```

  - Run `base.yml` playbook

  ```
  ansible-playbook -l ubuntu-lxc-template.home.prettybaked.com  playbooks/base.yml
  ```

- Validate Container Config

  - LDAP SSH user Login
  - User Home Directory CephFS + LDAP + AutoFS Mount
  - LDAP sudo privileges
  - CephFS Mounts for /data and /media

  ```
  ❯ ssh ubuntu-lxc-template

  Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.85-1-pve x86_64)

   * Documentation:  https://help.ubuntu.com
   * Management:     https://landscape.canonical.com
   * Support:        https://ubuntu.com/advantage

  ubuntu-lxc-template ajanis:~: ls
   Desktop                 TM_Backups
   Documents               Templates
   Downloads              'Temporary Items'
   Music                   Videos
  'Network Trash Folder'   healthcheck_not_redirect.conf
   Pictures                pbcopy
   Public                  rsyslog.conf.good
   PyCharm2021.1           settings-5-29-11.zip

  ubuntu-lxc-template ajanis:~: sudo su -

  root@ubuntu-lxc-template:~# df -h -t ceph
  Filesystem                                                                            Size    Used Avail Use% Mounted on
  10.0.10.201,10.0.10.202,10.0.10.203,10.0.10.204:/                                     4.4T 221G  4.2T   5% /media
  10.0.20.128,10.0.20.129,10.0.20.130,10.0.20.131:/                                     108T  69T   39T  65% /data
  10.0.20.128:6789,10.0.20.129:6789,10.0.20.130:6789,10.0.20.131:6789:/homedirs/ajanis  108T  69T   39T  65% /home/ajanis

  root@ubuntu-lxc-template:~# ls /data
  automation  datahealth.txt  images       nvr          ssl
  backups     frigate         isos         pbcopy       tv
  comics      git             movies       public_html
  configs     homedirs        nvidia_vgpu  scripts

  root@ubuntu-lxc-template:~# ls /media
  complete  incomplete  queued    template
  dump      logs        snippets  transcoding
  ```

- Convert the configured LXC container into a template via GUI

- Create new pre-configured LXC containers by `right-click` + `clone` on the template.

- Customize cloned container (e.g.: Static IP, Disk Size) if desired

- Start Container
