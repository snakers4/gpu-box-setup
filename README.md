
- [**Box specs and assembly**](#box-specs-and-assembly)
- [**Basic steps after installing Ubuntu**](#basic-steps-after-installing-ubuntu)
  - [**Creating users and importing their keys**](#creating-users-and-importing-their-keys)
  - [**Basic monitoring and productivity**](#basic-monitoring-and-productivity)
  - [**Installing NVIDIA drivers**](#installing-nvidia-drivers)
  - [**Mounting drives**](#mounting-drives)
- [**Tools for DL environment**](#tools-for-dl-environment)
  - [**Docker CE**](#docker-ce)
  - [**Nvidia-docker 2**](#nvidia-docker-2)
  - [**Basic dockerfile**](#basic-dockerfile)
- [**Connect to other cluster machines via 10 Gb/s LAN**](#connect-to-other-cluster-machines-via-10-gbs-lan)
- [**Port forwarding / ports available**](#port-forwarding--ports-available)
- [LVM array on the second box](#lvm-array-on-the-second-box)
  - [Device level](#device-level)
  - [Volume groups](#volume-groups)
  - [Create](#create)
  - [Creating FS and mounting](#creating-fs-and-mounting)
- [Prometheus](#prometheus)
  - [Download and install](#download-and-install)
    - [Possible options:](#possible-options)
    - [1) Download precompiled versions from *https://prometheus.io/download/*](#1-download-precompiled-versions-from-httpsprometheusiodownload)
    - [2) Hard way, build everything yourself](#2-hard-way-build-everything-yourself)
      - [1. Prometheus:](#1-prometheus)
      - [2. Alertmanager:](#2-alertmanager)
      - [3. Node_exporter:](#3-node_exporter)
      - [4. Nvidia_gpu_prometheus_exporter:](#4-nvidia_gpu_prometheus_exporter)
  - [Yaml files](#yaml-files)
      - [1. prometheus.yml](#1-prometheusyml)
      - [2. alertmanager.yml](#2-alertmanageryml)
      - [3. alert_rules.yml](#3-alert_rulesyml)
  - [Run everything](#run-everything)
  - [kill everything](#kill-everything)
- [**Use VsCode remote ssh development on WINDOWS 10**](#use-vscode-remote-ssh-development-on-windows-10)
- [**Advanced disk maintenance**](#advanced-disk-maintenance)
  - [**Create mount points and create disks**](#create-mount-points-and-create-disks)
  - [**Move docker folder**](#move-docker-folder)
  - [**Raid arrays**](#raid-arrays)
  - [**Disk encryption**](#disk-encryption)
  - [**Prevent docker daemon from loading**](#prevent-docker-daemon-from-loading)
- [**Email notifications**](#email-notifications)

# **Box specs and assembly**

- 1+ Nvidia 1080Ti GPUs (any modern Nvidia GPUs are ok);
- AMD Threadripper processor;
- Ample airflow for GPUs;

# **Basic steps after installing Ubuntu**

Update packages:
```
sudo apt update
sudo apt upgrade
```
In my case adding repositories was also required:

```
# add universe to end of each line
sudo nano /etc/apt/sources.list
```

Optionally use a plain firewall with `ufw`.

## **Creating users and importing their keys**

A group for all of the users to share folders:
```
sudo addgroup ds && \
sudo groupadd docker
```
Create a user and perform basic tasks with this user (note that I am using a github alias):
```
USER="YOUR_USER" && \
GROUP='ds' && \
sudo useradd $USER -s /bin/bash -m && \
sudo adduser $USER $GROUP && \
sudo mkdir -p /home/$USER/.ssh/ && \
sudo touch /home/$USER/.ssh/authorized_keys && \
sudo chown -R $USER:$USER /home/$USER/.ssh/ && \
sudo wget -O - https://github.com/$USER.keys | tail -n 1 | sudo tee -a /home/$USER/.ssh/authorized_keys && \
sudo adduser $USER docker
# sudo adduser $USER sudo
```

## **Basic monitoring and productivity**

Sudo w/o entering logpass each time:
```
# add manually to the bottom of the file
sudo visudo
# username ALL=(ALL) NOPASSWD: ALL
```

Prohibit password login:
```
sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
```

Tools:

```
sudo apt  install python3-pip
sudo apt  install tmux
sudo apt  install glances
sudo pip3 install gpustat
sudo apt  install lm-sensors
sudo apt  install ncdu
sudo apt  install unzip
sudo apt  install openvpn
sudo apt  install traceroute
```


## **Installing NVIDIA drivers**

```
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt install nvidia-driver-390
# reboot
nvidia-smi
```

## **Mounting drives**
Ensure that all members of group can read from folder, but cannot delete other people's files:
```
sudo mkdir /mnt/nvme
sudo chown -R :ds /mnt/nvme/
sudo chmod 2770 /mnt/nvme
```

Mount a pre-formatted NVME drive with data on it:
```
sudo  mount /dev/nvme1n1p1 /mnt/nvme
blkid /dev/nvme1n1p1
sudo echo 'UUID=379eade4-cf4e-4b42-bb49-efa025e81650 /mnt/nvme ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo mount -a
```

# **Tools for DL environment**

## **Docker CE**

Just follow the relevant instructions from [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository).

```
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

# for newer / odd Ubuntu versions you may have to tweak here
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce
sudo docker run hello-world
```

Add all of your users to docker group to grant them rights to run docker wo sudo
```
sudo usermod -aG docker $USER
```
Clean up:
```
# do not forget to relogin
# delete all containers
docker rm $(docker ps -a -q)
# delete all images
docker rmi $(docker images -q)
```

## **Nvidia-docker 2**

Just follow [here](https://github.com/NVIDIA/nvidia-docker)
Recently there was a rehaul of the docs - https://github.com/NVIDIA/nvidia-docker

Add the package repositories:
```
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
```
Install nvidia-docker2 and reload the Docker daemon configuration:
```
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd
```
Test nvidia-smi with the latest official CUDA image:
```
docker run --runtime=nvidia --rm nvidia/cuda:9.0-cudnn7-devel nvidia-smi
```
Clean up:
```
# delete all containers
docker rm $(docker ps -a -q)
# delete all images
docker rmi $(docker images -q)
```
## **Basic dockerfile**

Located in `Dockerfile`.

Key dependencies:
- Builds from official Ubuntu + CUDA image;
- Python from miniconda;
- Keras, TF and PyTorch;
- Basic DS / ML libraries;


# **OBSOLETE Connect to other cluster machines via 10 Gb/s LAN**

Have 2 machines with 10 Gbit/s port. Connect them via `6A` class patch-cord.

Find [physical](https://askubuntu.com/questions/22835/how-to-network-two-ubuntu-computers-using-ethernet-without-a-router) etherhnet devices on both machines:
```
ip a l
```
Make sure that both devices have no IP allocated (i.e. they are NOT primary Internet connections).
Machines
```
sudo ip ad add 10.0.0.10/24 dev enp7s0
sudo ip ad add 10.0.0.20/24 dev p2p1
```

```
ping 10.0.0.20
ping 10.0.0.10
```

Test [speed](https://www.cyberciti.biz/faq/how-to-test-the-network-speedthroughput-between-two-linux-servers/).


# **Port forwarding / ports available**

Ports forwarded for DS / ML work:
- Host ssh port `8027`;
- Jupyter ports `8882` `8883` `8884`;
- TensorBoard ports `6001` `6002` `6003`;

# LVM array on the second box

https://www.digitalocean.com/community/tutorials/how-to-use-lvm-to-manage-storage-devices-on-ubuntu-18-04

## Device level
see all compatible drives
`sudo lvmdiskscan`

lvm physical devices
```
sudo lvmdiskscan -l
sudo pvscan
sudo pvs
sudo pvdisplay
```

## Volume groups
The vgscan command can be used to scan the system for available volume groups.
It also rebuilds the cache file when necessary.
It is a good command to use when you are importing a volume group into a new system
```
sudo vgscan
sudo vgs -o +devices,lv_path
sudo vgdisplay -v
```

logical volumes
```
sudo lvscan
sudo lvs
sudo lvs --segments
sudo lvdisplay -m
```

## Create
```
sudo pvcreate /dev/nvme0n1p1 /dev/nvme1n1p1
# sudo pvremove
sudo lvmdiskscan -l
```
```
# WARNING: only considering LVM devices
# /dev/nvme0n1p1 [     931.51 GiB] LVM physical volume
# /dev/nvme1n1p1 [     931.51 GiB] LVM physical volume
# 0 LVM physical volume whole disks
# 2 LVM physical volumes
```
ttps://www.howtoforge.com/linux_lvm_p2
```
sudo vgcreate nvme_drives /dev/nvme0n1p1 /dev/nvme1n1p1
# vgrename fileserver data
sudo lvcreate --name nvme_lv --size 1.8T nvme_drives
```

## Creating FS and mounting
```
sudo mkfs.ext4 /dev/nvme_drives/nvme_lv
sudo mount /dev/nvme_drives/nvme_lv /mnt/nvme
```

# Prometheus
## Download and install
### Possible options:

### 1) Download precompiled versions from *https://prometheus.io/download/*

### 2) Hard way, build everything yourself
#### 1. [Prometheus](https://github.com/prometheus/prometheus):
```
$ mkdir -p $GOPATH/src/github.com/prometheus
$ cd $GOPATH/src/github.com/prometheus
$ git clone https://github.com/prometheus/prometheus.git
$ cd prometheus
$ make build
```
#### 2. [Alertmanager](https://github.com/prometheus/alertmanager):
```
$ mkdir -p $GOPATH/src/github.com/prometheus
$ cd $GOPATH/src/github.com/prometheus
$ git clone https://github.com/prometheus/alertmanager.git
$ cd alertmanager
$ make build
```

#### 3. [Node_exporter](https://github.com/prometheus/node_exporter):
```
$ go get github.com/prometheus/node_exporter
$ cd ${GOPATH-$HOME/go}/src/github.com/prometheus/node_exporter
$ make
```

#### 4. [Nvidia_gpu_prometheus_exporter](https://github.com/mindprince/nvidia_gpu_prometheus_exporter):
```
$ go get github.com/mindprince/nvidia_gpu_prometheus_exporter
$ cd ${GOPATH-$HOME/go}/src/github.com/mindprince/nvidia_gpu_prometheus_exporter
$ make
```

## Yaml files

#### 1. prometheus.yml
prometheus [config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) file, example that i use

```
global:
  # Set the scrape interval to every 15 seconds
  scrape_interval: 15s # Set the scrape interval to every 15 seconds
  # Evaluate rules every 15 seconds
  evaluation_interval: 15s

# Alertmanager configuration
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
    # Alertmanager port
      - "localhost:9093"

# Rules yaml file (additional metrics + alert rules)
rule_files:
  - "alert_rules.yml"

# A scrape configuration
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  # Where to listen to additional metric exporters
  # GPU metrics (Nvidia_gpu_prometheus_exporter)
  - job_name: 'gpu'
    static_configs:
    - targets: ['localhost:9445']

  # Node metrics (Node_exporter)
  - job_name: 'node'
    static_configs:
    - targets: ['localhost:9100']
```

#### 2. alertmanager.yml

alertmanager [config](https://prometheus.io/docs/alerting/configuration/) file, example
```

global:
  smtp_smarthost: smtp.gmail.com:587
  smtp_from: SOME_EMAIL
  smtp_auth_username: USERNAME
  smtp_auth_password: PASSWORD
  smtp_auth_identity: IDENTITY(EMAIL)

route:
  group_by: [Alertname]
  receiver: email-me
  # How long to wait before sending a notification again if it has already
  # been sent successfully for an alert
  repeat_interval: 2h

receivers:
- name: email-me
  email_configs:
  - to: aveysov@gmail.com, dvoronin322@gmail.com

```

#### 3. alert_rules.yml

metric [rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) for alertmanager (when to fire alarm), example
```
groups:
- name: box_2_stats
  rules:
  - alert: GPU_HIGH_TEMPERATURE
    # Fire when average gpu temperature for past 2 minutes more than 90 celsius
    expr: avg_over_time(nvidia_gpu_temperature_celsius[2m]) > 90
    for: 30s
    annotations:
        description: "{{ $value }} celsius mean GPU temperature for past 2 minutes!"

  - alert: CPU_HIGH_TEMPERATURE
   # Fire when average cpu temperature for past 2 minutes more than 90 celsius
    expr: avg_over_time(node_hwmon_temp_celsius[2m]) > 75
    for: 30s
    annotations:
        description: "{{ $value }} celsius mean CPU temperature for past 2 minutes!"

  - alert: RAM
   # Fire when available RAM < 500 MB
    expr: round((node_memory_MemAvailable_bytes) / 1024 / 1024) < 500
    for: 1m
    annotations:
        description: "Only {{ $value }} MB RAM available!"

  - alert: NVME_MEM
   # Alert when less than 10 GB available on NVME disk
    expr: round(node_filesystem_avail_bytes{mountpoint="/mnt/nvme"} / 1024 / 1024 / 1024) < 10
    for: 5m
    annotations:
        description: "{{ $value }} space available on /mnt/nvme!"
  
  - alert: SDE1_MEM
    expr: round(node_filesystem_avail_bytes{device="/dev/sde1"} / 1024 / 1024 / 1024) < 5
    for: 5m
    annotations:
        description: "{{ $value }} space available on SDE1!"

  - alert: MD
   # Fire when disk is not available
    expr: (node_md_disks_active - node_md_disks) > 0
    for: 10m
    annotations:
        description: "Something wrong with disk"

  - alert: IOWAIT
   # Fire when iowait > 0.85 per second for past 5 minutes
    expr: rate(node_cpu_seconds_total{mode="iowait"}[5m]) > 0.85
    for: 5m
    annotations:
        description: "High iowait value! ({{ $value }} mean for past five minutes)"
```

## Run everything
I use this .sh script in tmux to run everything at once
```
#!/bin/bash
cd node_exporter-0.18.1.linux-amd64/ && ./node_exporter \
& nvidia-docker run -p 9445:9445 -ti mindprince/nvidia_gpu_prometheus_exporter:0.1 \
& cd alertmanager-0.17.0.linux-amd64/ && ./alertmanager --config.file=alertmanager.yml \
& cd prometheus-2.10.0.linux-amd64/ && ./prometheus --config.file=./prometheus.yml --web.listen-address="0.0.0.0:9092" \

```

## kill everything 
`ctrl+c` in tmux session stops processes

to make sure everything is off use
`pgrep -f "alertmanager|node_exporter|prometheus"` and then `kill -TERM` processes

Nvidia_gpu_prometheus_exporter can be closed by shutting down docker container

# **Use VsCode remote ssh development on WINDOWS 10**

- **Docker: set up port forwarding and docker container ports:**
-- E.g. My port is 8022
-- Router port forwardng (i.e. your port will be 8023) or local ssh tunnel, i.e. `127.0.0.1 => 8023`
-- Expose port within Docker container in EXPOSE
-- Do Docker port forwarding when launching a container, i.e. -p 8023:22
-- Turn on ssh Daemon within container (service ssh start), test it, should be done each time. See Dockerfiles
-- Create /keras/.ssh/authorized_keys file and paste your public key there within the container
- **VScode setup on windows**
-- Download, install VScode (it said that you [needed](https://code.visualstudio.com/docs/remote/remote-overview) their bleeding edge build, but normal build works as well now);
-- Install ssh remote development plugin;
-- Create VScode ssh config (had to google their forums)
```
Host example-remote-linux-machine-with-identity-file
    User keras
    HostName 127.0.0.1
    Port 8022
    IdentityFile D:\CATS\ARE\FLUFFY\private_key_in_open_ssh_format.ppk
```
-- You will have the following problems on Windows 10
--- You will have to create USER/.ssh folder
--- You will have to set up permissions like in this comment (https://superuser.com/a/1329702) for the ssh private key file
--- Some other similar fail, I do not remember
- **Useful extensions I think are important**
-- Python
-- Linting (flake 8)
- **Open SSH format**
-- If you use PuTTY to create keys - you may need to use PyTTYgen to change the format of the key to open-ssh standard format

# **Advanced disk maintenance**

## **Create mount points and create disks**

**Create mountpoints:**

```
sudo mkdir /mnt/nvme
sudo mkdir /mnt/docker
sudo mkdir /mnt/dump
```

**Create a new partition on an nvme drive:**

Just an example. Do not follow this blindly.

```
sudo fdisk /dev/nvme1n1
# n 4 w
sudo fdisk /dev/nvme0n1
# n p 1 w
sudo mkfs -t ext4 /dev/nvme0n1p1
sudo mkfs -t ext4 /dev/nvme1n1p4
sudo  mount /dev/nvme0n1p1 /mnt/nvme
sudo  mount /dev/nvme1n1p4 /mnt/docker
sudo blkid /dev/nvme0n1p1
sudo echo 'UUID=bf373684-6885-4443-a809-d881a788a716 /mnt/nvme ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo blkid /dev/nvme1n1p4
sudo echo 'UUID=183135fb-4849-485f-84aa-afb53ad9ad40 /mnt/docker ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo mount -a
```

## **Move docker folder**

Just an example. Do not follow this blindly.

[Guide](https://medium.com/developer-space/how-to-change-docker-data-folder-configuration-33d372669056) and this [guide](https://stackoverflow.com/questions/24309526/how-to-change-the-docker-image-installation-directory/34731550#34731550)

Do this after encryption
```
sudo nano /lib/systemd/system/docker.service
sudo reboot now
```

## **Raid arrays**

As usual this guide [used](https://www.digitalocean.com/community/tutorials/how-to-create-raid-arrays-with-mdadm-on-ubuntu-18-04).

```
sudo lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
sudo mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd
cat /proc/mdstat
sudo mkfs.ext4 -F /dev/md0
sudo mkdir -p /mnt/dump
sudo mount /dev/md0 /mnt/dump
df -h -x devtmpfs -x tmpfs
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
echo '/dev/md0 /mnt/dump ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
```

## **Disk encryption**

```
sudo cryptsetup luksFormat --hash=sha512 --key-size=512 /dev/nvme1n1p1
sudo cryptsetup open --type=luks /dev/nvme1n1p1 nvme

sudo cryptsetup luksFormat --hash=sha512 --key-size=512 /dev/nvme0n1p4
sudo cryptsetup open --type=luks /dev/nvme0n1p4 docker

sudo pvcreate /dev/mapper/nvme
sudo vgcreate vg_nvme /dev/mapper/nvme
sudo lvcreate -n lv_nvme -l 100%FREE vg_nvme

sudo pvcreate /dev/mapper/docker
sudo vgcreate vg_docker /dev/mapper/docker
sudo lvcreate -n lv_docker -l 100%FREE vg_docker

sudo blkid /dev/nvme1n1p1
# /dev/nvme1n1p1: UUID="d75379aa-b095-4a3c-8fbf-218ebaf58675" TYPE="crypto_LUKS" PARTUUID="8ec6a65f-01"

sudo blkid /dev/nvme0n1p4
# /dev/nvme0n1p4: UUID="742a0a03-df61-4d9c-9308-26a4978dc55c" TYPE="crypto_LUKS" PARTUUID="3c5febf7-d09c-f54a-ab5b-c581322abaf5"

sudo mkfs.ext4 /dev/vg_docker/lv_docker
sudo mkfs.ext4 /dev/vg_nvme/lv_nvme

sudo mount /dev/vg_docker/lv_docker /mnt/docker
sudo mount /dev/vg_nvme/lv_nvme /mnt/nvme

sudo nano /etc/crypttab
nvme UUID=d75379aa-b095-4a3c-8fbf-218ebaf58675 none luks,discard
docker UUID=742a0a03-df61-4d9c-9308-26a4978dc55c none luks,discard

sudo blkid /dev/vg_docker/lv_docker
sudo blkid /dev/vg_nvme/lv_nvme

# this causes malfunction on boot
# because disk password prompt is on boot in console
sudo echo 'UUID=6502c02d-b7fe-4c1a-872c-6cabcc204c40 /mnt/nvme ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo echo 'UUID=07faea3b-53bd-4ccc-ae64-ba34d4a14616 /mnt/docker ext4 defaults 0 0' | sudo tee -a /etc/fstab

```

## **Prevent docker daemon from loading**

Because otherwise it will cause trouble with encrypted non-mounted disks

```
sudo systemctl disable docker.socket
sudo systemctl disable docker.service
sudo systemctl status docker
```


# **Email notifications**

```
sudo apt-get install ssmtp
nano /etc/ssmtp/ssmtp.conf
```

Or just look up the config in other servers

```
# some rubbish email
#
# START CONFIG
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
# root=postmaster
root=gmail-addresscom
# The place where the mail goes. The actual machine name is required no
# MX records are consulted. Commonly mailhosts are named mail.domain.com
# mailhub=mail
mailhub=smtp.gmail.com:587
AuthUser=gmail-addresscom
AuthPass=your_pass
UseTLS=YES
UseSTARTTLS=YES
# Where will the mail seem to come from?
rewriteDomain=gmail.com
# The full hostname
# hostname=snakers41-ubuntu
# not sure about what this line means
hostname=localhost
# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES
# END CONFIG

# IMPORTANT - turn on less secure apps in google account settings
# https://support.google.com/accounts/answer/6010255
```

Test email notifications
```
echo "Test message from Linux server using ssmtp" | sudo ssmtp -vvv destination-email-address@some-domain.com
```

Or a more detailed email
```
echo "Test message from Linux server using ssmtp" | sudo ssmtp -vvv aveysov@gmail.com

{
    echo To: nurtdinovadf@gmail.com
    echo From: aveysov@gmail.com
    echo Subject: The cat is on the mat!
    echo Testing email
} | ssmtp -vvv nurtdinovadf@gmail.com
```

Setup mdadm email notifications

```
sudo nano /etc/mdadm.conf # add email here
sudo mdadm --monitor --scan --test -1
```


# **Networking all the cluster machines via 10 Gb/s LAN**


Connect all machines in the cluster via 10 Gbit/s LAN via a switch.
Apply the following netplan config (i.e. `cat /etc/netplan/conf.yaml`)

At first note the interfaces on each box, i.e. `ip a`, write down the 10 Gbit/s interface and a slower interface

```
network:
  ethernets:
    p2p1:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.2.4/24
      optional: true
    p2p2:
      dhcp4: true
      optional: true
  version: 2
```

Then
```
sudo netplan try
```


Test [speed](https://www.cyberciti.biz/faq/how-to-test-the-network-speedthroughput-between-two-linux-servers/).


