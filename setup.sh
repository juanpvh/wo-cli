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


	if [ -e /usr/bin/rclone ]; then
		echo "${gb}${bf} Rclone Existe ⚡️${r}"
		else
		curl https://rclone.org/install.sh | sudo bash
		[ -e /usr/bin/rclone ] && echo "${gb}${bf} Rclone Instalado com sucesso! ⚡️${r}" || echo "${gb}${bf} Rclone Não foi Instalado! ⚡️${r}"
	fi

	echo "${gb}${bf} Configurar o Rclone para google drive? ⚡️${r}"
	echo -ne "${blf}Selecione uma das opcoes [y/n] [n]:${r} " ; read -i y INS1

	if [ "$INS1" = "y" ]; then
		echo -ne "${blf}Digite o nome do seu app [gdrive]:${r} " ; read -i y NAMEAPP
    	echo -ne "${blf}Digite o ID do Cliente:${r} " ; read IDCLIENT
    	echo -ne "${blf}Digite A Chave Secreta:${r} " ; read SECRETKEY

		rclone config create $NAMEAPP drive cliente_id $IDCLIENT client_secret $SECRETKEY config_is_local false scope drive.file
	
	else
		echo -e "${blf}${wb} Para configurar manualmente sua app para backup \nUse: rclone config${r}"
	fi
	
	if [ -e usr/local/bin/wo-cli ]; then
		echo "${gb}${bf} wo-cli Existe ⚡️${r}"

		else

	wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh && chmod +x /usr/local/bin/wo-cli
	echo "${gb}${bf} wo-cli Instalado ⚡️${r}"
	fi

	(crontab -l; echo "0 2 * * * /usr/local/bin/wo-cli -b 2> /dev/null 2>&1") | crontab -

	rm -rf $HOME/setup.sh