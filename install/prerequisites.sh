#!/bin/bash
set -e

HOSTNAME=$1
OS=$(grep '^ID' /etc/os-release)

sudo apt update && sudo apt full-upgrade -y && sudo apt -y autoremove && sudo apt autoclean
sudo apt install -y vim net-tools apt-transport-https ca-certificates curl containerd
if [[ $OS == *"ubuntu" ]]; then
    sudo apt install linux-modules-extra-raspi
fi

sudo sed -i "2 i 127.0.0.1\t$HOSTNAME" /etc/hosts

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/\[plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.runc.options\]/&\n \t\tSystemdCgroup = true/' /etc/containerd/config.toml

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system


if [[ $OS == *"ubuntu" ]]; then
    cgroup="$(head -n1 /boot/firmware/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" && echo $cgroup | sudo tee /boot/firmware/cmdline.txt
else
    cgroup="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" && echo $cgroup | sudo tee /boot/cmdline.txt
    sudo sed -i -e 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=0/g'  /etc/dphys-swapfile
fi


cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
vxlan
EOF

sudo modprobe overlay && sudo modprobe br_netfilter && sudo modprobe vxlan

sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

sudo reboot
