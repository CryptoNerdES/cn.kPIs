#!/bin/bash
set -e

sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 10 && kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "================ .kubeconfig ================"
cat $HOME/.kube/config
echo "================ .kubeconfig ================"

echo "================ kubeadm join ================"
kubeadm token create --print-join-command
echo "================ kubeadm join ================"