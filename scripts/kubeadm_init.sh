#! /bin/bash
IPADDRESS=$(ip address show dev eth0 | grep 'inet ' | awk '{print $2}' | cut -d"/" -f1)
echo "--> pull kubeadm images <--"
kubeadm config images pull

echo "--> run 'kubeadm init' <--"
kubeadm init --apiserver-advertise-address=$IPADDRESS --pod-network-cidr=10.244.0.0/16 > /tmp/kubeadm_init_output.txt

echo "--> setup $HOME/.kube/config <--"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "--> install flannel <--"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

