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
sudo addgroup ds
```
Create a user and perform basic tasks with this user (note that I am using a github alias):
```
USER="YOUR_USER" && \
GROUP='ds' && \
sudo useradd $USER && \
sudo adduser $USER $GROUP && \
sudo mkdir -p /home/$USER/.ssh/ && \
sudo touch /home/$USER/.ssh/authorized_keys && \
sudo chown -R $USER:$USER /home/$USER/.ssh/ && \
sudo wget -O - https://github.com/$USER.keys | sudo tee -a /home/$USER/.ssh/authorized_keys
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


# **Connect to other cluster machines via 10 Gb/s LAN**

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

