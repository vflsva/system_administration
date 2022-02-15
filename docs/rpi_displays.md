# info displays

- [info displays](#info-displays)
  - [resources](#resources)
  - [setup in kiosk mode](#setup-in-kiosk-mode)
    - [1) flash image](#1-flash-image)
    - [2) headless setup](#2-headless-setup)
      - [a) enable ssh](#a-enable-ssh)
      - [b) add network info](#b-add-network-info)
      - [c) eject card and mount it](#c-eject-card-and-mount-it)
    - [3) connect to the rpi](#3-connect-to-the-rpi)
    - [4) secure rpi](#4-secure-rpi)
      - [a) change hostname](#a-change-hostname)
      - [b) create new user and remove `pi` user](#b-create-new-user-and-remove-pi-user)
      - [c) require password for sudo](#c-require-password-for-sudo)
      - [d) use ssh keys](#d-use-ssh-keys)
      - [e) change ssh port, disable ssh pw, and disable root ssh](#e-change-ssh-port-disable-ssh-pw-and-disable-root-ssh)
      - [f) install unattended-upgrades](#f-install-unattended-upgrades)
      - [g) install fail2ban](#g-install-fail2ban)
      - [h) install ufw (firewall)](#h-install-ufw-firewall)
    - [5) setup kiosk mode](#5-setup-kiosk-mode)
      - [a) install minimum gui components](#a-install-minimum-gui-components)
      - [b) install chromium browser](#b-install-chromium-browser)
      - [c) edit openbox config](#c-edit-openbox-config)
      - [d) start x server on boot](#d-start-x-server-on-boot)
  - [create image of rpi](#create-image-of-rpi)
    - [1) find image](#1-find-image)
    - [2) unmount disk](#2-unmount-disk)
    - [3) create disk image](#3-create-disk-image)
    - [4) inspect image](#4-inspect-image)
    - [5) write image](#5-write-image)

## resources

- [Headless Raspberry Pi 3 B+ SSH WiFi Setup](https://desertbot.io/blog/headless-raspberry-pi-3-bplus-ssh-wifi-setup)
- [Raspberry Pi Touchscreen Kiosk Setup](https://desertbot.io/blog/raspberry-pi-touchscreen-kiosk-setup)
- [How To Create Disk Image on Mac OS X With dd Command](https://www.cyberciti.biz/faq/how-to-create-disk-image-on-mac-os-x-with-dd-command/)

## setup in kiosk mode

This process is for setting up a new rpi from scratch for using as a display.

### 1) flash image

Flash a new sd card with the raspian lite image (64 or 32, I'm using 64).

[rpi imager](https://www.raspberrypi.com/software/)

### 2) headless setup

#### a) enable ssh

At the root of the boot disk (sd card) add an empty file named `ssh`.

`touch ssh`

#### b) add network info

At the root of the boot disk (sd card) add file named `wpa_supplicant.conf`. You can copy the contents from the command below or just run it in the root of boot disk

```sh
cat <<FILE > wpa_supplicant.conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="<NETWORK-NAME>"
    psk="<NETWORK-PASSWORD>"
}
FILE
```

#### c) eject card and mount it

Eject the sd card, mount it into the rpi, and startup the pi.

### 3) connect to the rpi

Connect to the rpi over ssh.

```sh
# clear old rpi references
ssh-keygen -R raspberrypi.local

# connect
ssh pi@raspberrypi.local

# when prompted for pw: raspberry
```

### 4) secure rpi

The following steps are meant to help keep the rpi secure on the local network.

#### a) change hostname

__NOTE:__ increment number for display (`vfldisplay01`) depending on how many already exist

1. update rpi
   - `sudo apt update && sudo apt upgrade`
2. edit hosts file
   - `sudo nano /etc/hosts`
   - on the bottom line change `127.0.0.1   raspberrypi` to `127.0.0.1   vfldisplay01`
3. edit hostname file
   - `sudo nano /etc/hostname`
   - enter `vfldisplay01`
   - change `raspberrypi` to `vfldisplay01`

#### b) create new user and remove `pi` user

__NOTE:__ see VFL account info spreadsheet for current rpi username and password
  
1. create new user
   - `sudo adduser <username>`
2. give user sudo privelage
   - `sudo adduser <username> sudo`
3. switch user
   - `su <username>`
4. delete `pi` user
   - `sudo deluser -remove-home pi` 
5. restart computer and reconnect
   - `sudo reboot`
   - reconnect: `ssh <username>@vfldisplay01.local`

#### c) require password for sudo

1. edit sudoers file
   - `sudo nano /etc/sudoers.d/010_pi-nopasswd`
   - change line `pi ALL=(ALL) NOPASSWD: ALL` to `vfl ALL=(ALL) PASSWD: ALL`
2. repeat for all users with sudo access

#### d) use ssh keys

__NOTE:__ the keys are created on a mac or linux (client) computer

1. generate keys
   - `ssh-keygen -t rsa`
   - name as: `/Users/<username>/.ssh/vfl_rpi`
2. copy public key to rpi
   - `ssh-copy-id -i ~/.ssh/vfl_rpi.pub <username>@vfldisplay01.local`
3. add key to ssh-agent
   - `ssh-add ~/.ssh/vfl_rpi`

#### e) change ssh port, disable ssh pw, and disable root ssh

1. edit ssh config file
   - `sudo nano /etc/ssh/sshd_config`
2. change line `Port 22` to `Port 5050`
3. change line `PasswordAuthentication yes` to `PasswordAuthentication no
4. check root login is disabled
   - line should be commented out `#PermitRootLogin prohibit-password`

#### f) install unattended-upgrades

__NOTE:__ will only install security updates

1. install `unattended-upgrades`
   - `sudo apt install -y unattended-upgrades`
2. edit config for schedule of updtaes
   - `sudo nano /etc/apt/apt.conf.d/02periodic`
   - enter the following:
     ```sh
     APT::Periodic::Enable "1";
     APT::Periodic::Update-Package-Lists "1";
     APT::Periodic::Download-Upgradeable-Packages "1";
     APT::Periodic::Unattended-Upgrade "1";
     APT::Periodic::AutocleanInterval "1";
     APT::Periodic::Verbose "2";
     ```

#### g) install fail2ban

__NOTE:__ daemon to ban hosts that cause multiple authentication errors (default, ban attacker 10 min after 5 failures)

1. install
   - `sudo apt install -y fail2ban`

#### h) install ufw (firewall)

1. install
   - `sudo apt install -y ufw`
2. setup defaults
   - `sudo ufw default deny incoming`
   - `sudo ufw default allow outgoing`
3. allow access from only your computer
   - by ip: `sudo ufw allow 5050`
4. enable the firewall
   - `sudo ufw enable`
   - __WARN:__ starts immediately and may disconnect you - make sure settings are correct

### 5) setup kiosk mode

These are steps to install software required to run a pi as a "kiosk".

#### a) install minimum gui components

`sudo apt-get install -y --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox`

#### b) install chromium browser

`sudo apt-get install -y --no-install-recommends chromium-browser`

#### c) edit openbox config

__NOTE:__ When openbox launches at startup it will run two scripts in the /etc/xdg/openbox folder - first, environment and second, autostart

1. edit `environment`
   - `sudo nano /etc/xdg/openbox/environment`
   - add line `export KIOSK_URL=<url>`
2. edit `autostart`
   - `sudo nano /etc/xdg/openbox/autostart`
   - add lines:
   ```sh
   xset -dpms            # turn off display power management system
   xset s noblank        # turn off screen blanking
   xset s off            # turn off screen saver

   # remove exit errors from the config files that could trigger a warning

   sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/'Local State'

   sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences

   # run chromium in kiosk mode
   chromium-browser  --noerrdialogs --disable-infobars --check-for-update-interval=31536000 --kiosk $KIOSK_URL
   ```

#### d) start x server on boot

1. edit/create `.bash_profile`
   - `sudo nano ~/.bash_profile`
   - add line to bottom `[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx -- -nocursor`
2. restart the rpi.
   - `sudo reboot`

Should start and load webpage!

## create image of rpi

Steps to create image of rpi to be used for multiple devices. This was done on a mac with the `dd` command.

### 1) find image

`diskutil list`

Find the corresponding path, mine was `/dev/disk6`

### 2) unmount disk

`diskutil unmountDisk /dev/<disk>`

### 3) create disk image

`sudo dd if=/dev/<disk> of=vfl-rpi-display-backup.02-07-2022.img bs=1m`

### 4) inspect image

`file <image>`

### 5) write image

Using the rpi imager, select the created image and write to sd card.

__WARN:__ make sure to create a new hostname for each new rpi (see [4.a change hostname](#a-change-hostname)
