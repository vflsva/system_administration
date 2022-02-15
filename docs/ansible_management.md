# using ansible to manage windows hosts

- [using ansible to manage windows hosts](#using-ansible-to-manage-windows-hosts)
  - [references](#references)
  - [run ansible playbooks against windows hosts](#run-ansible-playbooks-against-windows-hosts)
    - [1) create an inventory file under `inventories\`](#1-create-an-inventory-file-under-inventories)
    - [2) test connection](#2-test-connection)
    - [3) set env vars](#3-set-env-vars)
    - [4) test run it](#4-test-run-it)
    - [5) run playbook](#5-run-playbook)
    - [6) create system image and restore new computers](#6-create-system-image-and-restore-new-computers)
    - [7) get ip from new computer (run in powershell)](#7-get-ip-from-new-computer-run-in-powershell)
    - [8) add all new ip's to ansible hosts file (make sure to add hostname you want for new computer)](#8-add-all-new-ips-to-ansible-hosts-file-make-sure-to-add-hostname-you-want-for-new-computer)

## references

- [Ansible.Windows - plugins index](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html)
- [Community.Windows - plugins index](https://docs.ansible.com/ansible/latest/collections/community/windows/index.html#plugins-in-community-windows)
- [users and groups](https://docs.ansible.com/ansible/latest/user_guide/windows_usage.html#set-up-users-and-groups)
  - [User Rights Assignment Settings](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd349804(v=ws.10))
- [installing updates](https://docs.ansible.com/ansible/latest/user_guide/windows_usage.html#installing-updates)
- [Top 10 Most Important Group Policy Settings for Preventing Security Breaches](https://www.lepide.com/blog/top-10-most-important-group-policy-settings-for-preventing-security-breaches/)

*creating image and restoring from image*

- [How to make a full backup of your Windows 10 PC](https://www.windowscentral.com/how-make-full-backup-windows-10)
  - [How to install Windows 10 from USB with UEFI support](https://www.windowscentral.com/how-create-windows-10-usb-bootable-media-uefi-support)

## run ansible playbooks against windows hosts

### 1) create an inventory file under `inventories\`

```yml
# file path and name: inventories/example_inventory.yml
# (create on ansible control host)

windows:
  hosts:
    <ip-address>:
  vars:
    ansible_user: ansible
    ansible_connection: winrm
    ansible_port: 5986
    ansible_winrm_scheme: https
    ansible_winrm_transport: certificate
    ansible_winrm_server_cert_validation: ignore
    ansible_winrm_cert_pem: <path-to-pem>
    ansible_winrm_cert_key_pem: <path-to-key-pem>
```

### 2) test connection

`export no_proxy=*; ansible windows -i inventories/example_inventory.yml -m win_ping`

### 3) set env vars

` export no_proxy=*; export STAFF_PW=<staff-pw>"; export STUDENT_PW="<student-pw>`

### 4) test run it

WARN: if new setup, odds are this will fail

`ansible-playbook -i inventories/windows.yml playbooks/windows_users.yml --check`

### 5) run playbook

`ansible-playbook -i inventories/windows.yml playbooks/windows_users.yml`

### 6) create system image and restore new computers

### 7) get ip from new computer (run in powershell)

`(Get-NetIPAdress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress`

or 

`(Get-NetIPAdress -AddressFamily IPv4 -InterfaceAlias 'Ethernet 3').IPAddress`

### 8) add all new ip's to ansible hosts file (make sure to add hostname you want for new computer)
