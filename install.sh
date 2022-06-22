#!/bin/bash
sudo apt update && sudo apt upgrade -y && sudo apt -y dist-upgrade && sudo apt -y autoremove && sudo apt autoclean
sudo apt install -y  vim net-tools apt-transport-https ca-certificates curl linux-modules-extra-raspi containerd

sudo hostnamectl set-hostname master

sudo sed -i '2 i 127.0.0.1 master' /etc/hosts

sudo reboot

sudo mkdir -p /etc/containerd
sudo su -
containerd config default  /etc/containerd/config.toml > /etc/containerd/config.toml
vim /etc/containerd/config.toml
exit

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull

cgroup="$(head -n1 /boot/firmware/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1" && echo $cgroup | sudo tee /boot/firmware/cmdline.txt

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
vxlan
EOF

sudo modprobe overlay && sudo modprobe br_netfilter && sudo modprobe vxlan


# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo reboot

sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock --set image-endpoint=unix:///run/containerd/containerd.sock

sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master- && kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml