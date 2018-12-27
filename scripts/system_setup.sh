#! /bin/bash

# disable swap since kubeadm documentation suggests disabling it
swapoff -a
sed -i '/swap/d' /etc/fstab

# disable firewalld and SELinux
systemctl disable firewalld
systemctl stop firewalld
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
