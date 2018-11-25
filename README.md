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
sudo ip ad add 10.0.0.20/24 dev p2p2
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
