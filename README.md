# workstation management for the vfl

- [workstation management for the vfl](#workstation-management-for-the-vfl)
  - [general overview](#general-overview)
  - [workstations](#workstations)
  - [documentation breakdowns](#documentation-breakdowns)
    - [ansible_setup.md](#ansible_setupmd)
    - [ansible_management.md](#ansible_managementmd)
    - [appointment_process.md](#appointment_processmd)
    - [rpi_display.md](#rpi_displaymd)
    - [security_practices.md](#security_practicesmd)
    - [software.md](#softwaremd)

## general overview

This is good ol' mono-repo for system adminstration for the VFL. This repository contains documentation and code used to maintain the computers and other services at the VFL. 

## workstations

The workstation computers at the vfl are desktop computers (from boxx) running Windows 10. There are 4 computers (see breakdown below): two general workstations, one render workstation, and one VR workstation. 

To manage the computers (permissions, updates, etc.) I use [ansible](https://www.ansible.com/). 

The process to setup a windows machine for management by ansible requires a bunch of steps. The idea is to only do this once on one new windows machine, then make a system image of the computer, which then can be used for any new machines. The new machines then can all be managed and maintained via ansible.

I have included all the code necessary to do this setup. The scripts are meant to be run in a *nix shell (bash, zsh, etc) or powershell. They can be found in this repo in the `workstations/` under `ansible_control_host/` and `windows_host/`. Please run scripts from the `workstations/` directory (relative paths in scripts assume this).

## documentation breakdowns

### ansible_setup.md

How to setup windows hosts to be managed by ansible.

### ansible_management.md

How to manage the windows hosts with ansible.

### appointment_process.md

How the appointment process works and the software used to maintain it. 

### rpi_display.md

How to setup a raspberry pi for running the info display monitors for the VFL.

### security_practices.md

TODO: ...

### software.md

Software installed on computers and printers/machines they are connected too.
