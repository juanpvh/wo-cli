#!/usr/bin/env bash

#var
PASSWORD=$(openssl rand -base64 32)

#export RESTIC_REPOSITORY=/mnt/gdrive/restic
#export RESTIC_PASSWORD=$PASSWORD

#instalando ocamlfuse

apt-get install software-properties-common
add-apt-repository ppa:alessandro-strada/ppa
apt-get update
apt-get install google-drive-acamlfuse

google-drive-ocamlfuse
mkdir /mnt/gdrive

echo -ne "👉  Insira o ID do google drive: " ; read ID_GD
echo -ne "👉  Insira a SECRET do google drive: " ; read SECRET_GD

google-drive-ocamlfuse -headless -label gdrive -id $ID_GD -secret $SECRET_GD /mnt/gdrive/restic

echo "Senha Gerada: $PASSWORD"
echo "export RESTIC_REPOSITORY=/mnt/gdrive/restic" >> /etc/profile
echo "export RESTIC_PASSWORD=$PASSWORD" >> /etc/profile

apt-get install restic

restic init --repo /mnt/gdrive/restic