#!/usr/bin/env bash

bb=`tput setab 0` #set background black
bf=`tput setaf 0` #set foreground black
gb=`tput setab 2` # set background green
gf=`tput setab 2` # set background green
blb=`tput setab 4` # set background blue
blf=`tput setaf 4` # set foreground blue
rb=`tput setab 1` # set background red
rf=`tput setaf 1` # set foreground red
wb=`tput setab 7` # set background white
wf=`tput setaf 7` # set foreground white
r=`tput sgr0`     # r to defaults

clear
cd ~

echo -ne "${gb}${bf}Digite um Nome Host para o Rclone:️${r} " ; read VARHOST
echo -ne "${gb}${blf}Na Proxima etapa o rclone solicitara o \"name\" Utilize \"${VARHOST}\" - APerter ENTER para Prosseguir.${r} " ; read APERT
sed -i s/^HOSTCLONE=.*/HOSTCLONE=$VARHOST/ /usr/local/bin/wo-cli
# Instalando Rclone 

	if [ -e /usr/bin/rclone ]; then
		echo "${gb}${bf} Rclone Instalado ⚡️${r}"
	else
		curl https://rclone.org/install.sh | sudo bash
		wait
		rclone config create $VARHOST
	fi
	