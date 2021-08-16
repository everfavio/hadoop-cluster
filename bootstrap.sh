#!/usr/bin/env bash
# establecemos la interfaz de debian como no interactiva
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get -y install openssh-server
sudo apt-get -y install net-tools
sudo apt-get -y install build-essential
sudo apt-get -y install vim
sudo apt-get -y install dirmngr
sudo apt-get -y install gnupg
sudo apt-get -y install apt-transport-https
sudo apt-get -y install software-properties-common
sudo apt-get -y install ca-certificates
# instalando java
sudo apt-get install default-jre -y
sudo apt-get install default-jdk -y
# instalando docker


#configurando ssh user
sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
systemctl restart sshd.service
## creamos el usuario
useradd -m -s /bin/bash hadoop
## establecemos la contraseña ('usuario:password')
echo 'hadoop:hadoop' | chpasswd
## agregamos al nuevo usuario al grupo sudoers
echo 'hadoop  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
## generamos las llaves ssh para habilitar la autenticación ssh
sudo su hadoop
cd
ssh-keygen -t dsa -N "hadoop" -f "$HOME/.ssh/id_rsa"
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub>> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

exit
