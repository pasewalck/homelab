# My Rasberry PI Home Lab Journey

After about a year of on and off working on this besides my studies and other projects I finally have a basic setup to my liking.

Originally inspired by a [Rasberry PI Nas Project by Jeff Geerling](https://www.jeffgeerling.com/blog/2024/radxas-sata-hat-makes-compact-pi-5-nas/) and later also by [A similar Build by Michael Klements](https://www.youtube.com/watch?v=vIEjdjS7uVg) I decided to build my homelab with a Rasberry PI 5 and the [Radxa SATA HAT](https://docs.radxa.com/en/accessories/storage/penta-sata-hat/penta-for-rpi5).

I also got the [Top Board from Radxa](https://docs.radxa.com/en/accessories/storage/penta-sata-hat/sata-hat-top-board) that is designed to work in tandem with their HAT.

I ended up doing some hardware modifications compared to how the HAT is used in my original aspirations mentioned above, which I plan on writing about here in the future.

I use the latest version of Raspberry Pi OS Lite (based on Debian Trixie). Currently, I just use Docker Engine with Docker Compose to manage my services and am very happy with that. But I plan on trying out something like Portainer in the future.

Radxa also provides software managing their Top Board display and fan, which they unfortunately don't seem to maintain any more. But to our luck there are numerous forks and even a [full rewrite in c](https://github.com/kYc0o/radxa-penta-sata-hat-top-board-ctrl-c/tree/main) that are updated. I ended up creating [my own fork](https://github.com/pasewalck/rockpi-penta) from a [fork by Igor Petrov](https://github.com/Pudel-des-Todes/rockpi-penta).

## Root Disk Encryption

I use the disk encryption scripts provided in [sdm](https://github.com/gitbls/sdm/). Their documentation on this topic can be found [here](https://github.com/gitbls/sdm/blob/master/Docs/Disk-Encryption.md).

Note: For my setup with Debian Trixie I ran into the following [issue](github.com/gitbls/sdm/issues/344). The fix proposed by gitbls worked for me. Updating boot/firmware/config.txt with:
- Adding ```kernel=kernel8.img```.
- And verifying that ```auto_initramfs=1``` is enabled.

I also use https://github.com/pasewalck/gatekeeper-disks for automatic unlock on boot.

## RAID Array with Encrpytion

For me it came down to choosing between using ZFS and RAID 1. Due to only having two SSDs at the time of writing this, RAID5 was out of the picture.

I personally decided to go for classic RAID but am definitely looking forward to try ZFS in the future.

I opted for setting up encryption on top of the RAID array, as, from my understanding, this is generally recommended. I don't use a logical file system setup between the encryption and file system layer, due to not seeing any benefits in that for my setup.

### Commands for my **specific** setup

Install mdadm:

```
sudo apt install mdadm
```

Use ```lsblk``` to check your disks names. For me they are ```sda``` and ```sdb```.

Create a partition table on each disk:
```
sudo parted -s /dev/sda mklabel gpt
sudo parted -s /dev/sdb mklabel gpt
```
Create partitions and allocate available space on each disk:
```
sudo parted -s /dev/sda mkpart primary 1MiB 100%
sudo parted -s /dev/sdb mkpart primary 1MiB 100%
sudo parted -s /dev/sda set 1 raid on
sudo parted -s /dev/sdb set 1 raid on
```
Create the actual RAID Array "md0" (in my case with RAID 1):
```
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1
```
Setup mdadm to automatically start on boot:
```
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
```
Setup the encryption:
```
sudo cryptsetup luksFormat /dev/md0
```
Unlock device and create a file system (this is where you would create a logical file system).
```
sudo cryptsetup open /dev/md0 raid1crypt
sudo mkfs.ext4 /dev/mapper/raid1crypt
```
### Auto Unlocking and Mounting

I didn't get crypttab to automatically unlock my volumes for a reason not fully clear to me. I ended up writing a small service to do the decryption and mounting due to also wanting to try that out anyway.

I created a service in ```/etc/systemd/system/luks-auto-unlock.service``` that waits for my raid array ```dev-md0``` to come up (Also I specifically to start before docker):

```
[Unit]
Description=Unlock LUKS Volumes
DefaultDependencies=no
Before=local-fs.target
Before=docker.service

After=dev-md0.device
BindsTo=dev-md0.device

[Service]
Type=oneshot
ExecStart=/root/unlock-raid-script.sh
RemainAfterExit=yes
TimeoutSec=60

[Install]
WantedBy=local-fs.target
```

Also in ```/etc/systemd/system/docker.service.d/override.conf``` I specify docker to wait for my service with:

```
[Unit]
After=luks-auto-unlock.service
Requires=luks-auto-unlock.service
```

The linked script ```/root/unlock-raid-script.sh``` looks as follows:

```
#!/bin/bash
set -e

MAPPER_NAME="raid1crypt"
MAPPER_PATH="/dev/mapper/$MAPPER_NAME"
LUKS_DEVICE="/dev/md0"
KEYFILE="/root/<keyname>.key"
MOUNT_POINT="/mnt/<some name>"

if [ ! -e "$MAPPER_PATH" ]; then
    echo "Unlocking $LUKS_DEVICE as $MAPPER_NAME..."
    cryptsetup luksOpen "$LUKS_DEVICE" "$MAPPER_NAME" --key-file "$KEYFILE"
else
    echo "$MAPPER_NAME already unlocked."
fi

if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

COUNTER=0
MAX_WAIT=30
while [ ! -b "$MAPPER_PATH" ]; do
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo "Error: Timeout waiting for $MAPPER_PATH."
        exit 1
    fi
    echo "Waiting for $MAPPER_PATH to appear..."
    sleep 1
    ((COUNTER++))
done

if mountpoint -q "$MOUNT_POINT"; then
    echo "The device is already mounted on $MOUNT_POINT."
else
    if sudo mount -o defaults $MAPPER_PATH "$MOUNT_POINT"; then
        echo "Volume successfully mounted at $MOUNT_POINT"
    else
        echo "Error mounting $MAPPER_PATH."
        exit 1
    fi
fi
```

## Access to my Home Lab (and its services)

To access my home lab from anywhere, I use a cheap VPS (512 MB RAM and 5 GB disk) to host a WireGuard server that my home lab is connected to.

<img width="600" alt="Hmlb" src="https://github.com/user-attachments/assets/614b18d2-c0aa-401a-bcb9-c5dca92ba55b" />

That allows me to connect from my laptop to the VPS from anywhere via WireGuard and access my homelab's web apps and SSH in directly. Also, I have an NGINX web server setup on the VPS to forward any incoming web traffic to the homelab. This allows me to also use my WebApps without needing an authenticated WireGuard client.

```
stream {
    upstream backend {
        server wireguard_homelab_ip:80;
    }
    server {
        listen 80;
        proxy_pass backend;
    }
    upstream backend_https {
        server wireguard_homelab_ip:443;
    }
    server {
        listen 443;
        proxy_pass backend_https;
    }
}
```

I worked on a small setup script bundle to improve the setup for this in https://github.com/pasewalck/homelab-guide/vpn-setup/. It should be usable by running the following **on the VPS (WireGuard server)**:

```
curl -fsSL https://github.com/pasewalck/homelab-guide/blob/main/vpn-setup/client.js -o ./server.sh && sudo bash ./server.sh
```

On my home lab, I simply have NGINX Proxy Manager running. Note that running NGINX Proxy Manager on your VPS with proxy pass would also be a valid option and would make it easier to filter traffic before it ever hits the home lab; however, it prevents you from handling TLS/SSL in the home lab, which improves security if you don't fully trust the VPS.
