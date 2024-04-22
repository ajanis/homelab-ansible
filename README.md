# HomeLab Ansible

Maybe this will make a good blog post

## Starting Over

### The 'what'

This ansible project was originally a hodge-podge of playbooks and group/host vars built around roles that catered specifically to our requirements.  Up until this point, I had primarily used salt.  The rapid adoption of ansible (when compared to the somewhat dubious road ahead of Salt) and the ease of initial deployment was appealing.  We also had a need for both one-off, throw-away playbooks and stable, re-usable roles for key infrastructure components - so Ansible seemed to fit nicely.

More than just a home-lab project, this has served as a learning environment where deployment methods have changed significantly or entire services have been forklift-upgraded (and then integrated into the project) to incorporate services or projects we wanted to learn for ourselves or to support professional projects/goals.

### The 'how'

As we had only recently started to learn and use ansible, some of the roles used in this project were forked and modified as needed.  Some of our own roles were not created with an eye on best-practices. Compounding that issue is the fact that this project spans *many* Ansible, Python, and OS releases; so there is an enormous gap in syntax, patterns, module use (or lack thereof), testing, documentation, etc..

There are entire projects that have been integrated (cephadm-ansible for example). In that case, I only included the modules, preferring instead to create our own roles and playbooks, reassign vars to keep them consistent and to leverage our existing dynamic inventory sources.

But all of these changes over time have introduced so much cardinality to variables alone that maintaining this thing is untenable.  Also trying to implement fixes across several repos while continuing to use (and likely modify) them has proven diffcult and time consuming.

### The 'why'

We have decided to start over in such a way that we can continue use of our existing project and without worrying about impossible merges and documentation that will be rendered mostly worthless.

Besides the obvious benefits of the aforementioned fixes, starting fresh will bring with it an opportunity to write proper tests, maintain documentation and add additional CI workflows where they have deserately been needed.

## The Outline

### What to keep

Certain components will be retained since they will not change much or at all.  They may be moved around though.

- Module python code
- Dynamic Inventory
- Collection Includes
- Role Includes

### Design Overhaul

Several of our core roles have been updated to a point that the variables are more-or-less unified.  However they will be rewritten to ensure variable consistency across the project and other roles.

- Variables specific to that role will keep their correct *role*_var syntax. (ex: `grafana_api_user`)
- Variables that should be generic (ex: `data_mount`, `transcode_dir`) will be kept generic for simplicity.

#### Here's a quick example

- A `mediaservices` and `downloadservices` and `plex` playbook (each deployed on it's own vm) will all use `data_mount` and `transcode_dir` as well as `media_uid` and  `media_gid`

    These could be defined in a vars file named `media.yml`

    ```yaml
    data_mount: data
    media_path: /{{ data_mount }}/media
    media_metadata_path: /{{ data_mount }}/metadata
    media_uid: 1000
    media_gid: 1000
    ```

    And used in a play to create the bind mounts for a docker container.

- A `cephfs.yml` vars file may contain vars specific to that role which include vars from `media.yml`

    ```yaml
    cephfs_fsid: 12345
    cephfs_user: client.mounts
    cephfs_secret: "{{ vault_cephfs_mounts_secret }}"
    cephfs_dirs:
      - path: cephfs:/{{data_mount}}
        admin: "{{ cephfs_user }}"
        passwd: "{{ vault_cephfs_mounts_secret }}"
        fsid: "{{ cephfs_fsid }}"

    ```

    A play implementing that role would include the `media` vars

    ```yaml
    vars_files:
      - media.yml
      - ceph.yml
    roles:
      - cephfs
    ```

- An `openldap` role may need `openldap_autofs_list` containing mount points and gids. This list is specific to the `openldap` role, but the required vars would be included in the play.

  ```yaml
  vars_files:
    - media.yml
    - ceph.yml
    - openldap.yml
  ```

  The vars file `openldap.yml` may include custom values for role-specific vars, which may in turn include custom values from `ceph.yml` which includes vars from `media.yml` :

  ```yaml

  # {role}/defaults/main.yml
  openldap_domain: ""
  openldap_server_uri: <my_ip>
  openldap_dc: "dc={{ ',dc='.join( openldap_domain.split('.') ) }}"
  openldap_bind_dn: "cn=Manager,{{ openldap_dc }}"
  openldap_admin_ou: "ou=admin,{{ openldap_dc }}"
  openldap_autofs_mounts: []

  # media.yml
  domain: constructorfleet.stream

  # cephfs.yml
  cephfs_fsid: 12345
  cephfs_user: client.mounts
  cephfs_secret: "{{ vault_cephfs_mounts_secret }}"

  # openldap.yml
  openldap_domain: mydomain.com
  automount_ou: "ou=automount,{{ admin_ou }}"
  auto_master_ou: "ou=auto.master,{{ automount_ou }}"
  auto_data_ou: "ou=auto.data,{{ automount_ou }}"
  auto_home_ou: "ou=auto.home,{{ automount_ou }}"

  # playboooks/{play}.yml
  vars:
    my_mount_options: "user={{ cephfs_user}},secret={{ cephfs_secret }}"
    openldap_autofs_mounts:
      - mp: "/{{ data_mount }}"
        cn: "{{ data_mount }}"
        dn: "cn={{ data_mount }},dn={{ openldap_bind_dn }}"
        ou: "{{ auto_data_ou }}"
        attributes: |
          cn: "{{ data_mount }}"
          automountInformation: "{{ my_mount_options }}"
      - mp: "/home"
        cn: "{{ data_mount }}"
        dn: "cn=/home,dn={{ openldap_bind_dn }}"
        ou: "{{ auto_data_ou }}"
        attributes: |
          cn: "{{ data_mount }}"
          automountInformation: "{{ my_mount_options }}"

  roles:
    - openldap
  ```

  The `openldap` role itself may include tasks such as:

  ```yaml
  # roles/openldap/tasks/automount.yml
    - name: Create autoFS CNs
      community.general.ldap_entry:
        server_uri: "{{ openldap_server_uri }}"
        bind_dn: "{{ openldap_bind_dn }}"
        bind_pw: "{{ openldap_bind_pw }}"
        dn: "{{ item.dn }}"
        objectClass:
          - top
          - automount
        attributes: "cn={{item.cn}}"
        state: present
      loop: "{{ openldap_autofs_mounts }}"
      loop_control:
        label: "{{ item.dn }}"
      notify:
        - restart_ns_daemons

    - name: Populate or Update autoFS CNs
      community.general.ldap_attrs:
        dn: "{{ item.dn }}"
        attributes: "{{ item.attributes }}"
        state: exact
        bind_dn: "{{ openldap_bind_dn }}"
        bind_pw: "{{ openldap_bind_pw }}"
      loop: "{{ openldap_autofs_mounts }}"
      loop_control:
        label: "{{ item.dn }}"
      notify:
        - restart_ns_daemons

- As intended, playbooks should be specific, roles should be generic.
Playbooks may include multiple plays (each with their own `vars_files` and `vars`) to accomplish desired role-specific vars and state.

- While multiple plays may be defined in a playbook, and they may all include the same `vars_files` and may include either `roles` or run one-off `tasks`, I intend to avoid including `playbooks` when possible to avoid conflicting vars.

All of this of course is nothing new and should not be groundbreaking to anyone familiar with ansible.  The bulk of the work here will be in refactoring roles with unified variables and in creating new playbooks with updated syntax for role and var inclusion.
