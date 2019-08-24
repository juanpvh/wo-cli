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

echo -e "${gf}${bf}INSTALANDO WO-CLI...${r}"
{

[ -e /usr/local/bin/wo-cli ] && echo "${gb}${bf} wo-cli Existe ⚡️${r}" || wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
 chmod +x /usr/local/bin/wo-cli
} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${blf}wo-cli Instalado com Sucesso!${r}   [${gb}${bb}OK${r}]"
        echo ""
    else
        echo -e "${blf}Instalação do WO-CLI${r}   [${gb}${bb}FALHOU${r}]"
        echo -e "${blf}Verifique o arquivo /tmp/registro.log${r}"
    fi

(crontab -l; echo "0 2 * * * /usr/local/bin/wo-cli -b 2> /dev/null 2>&1") | crontab -

rm -rf $HOME/install.sh