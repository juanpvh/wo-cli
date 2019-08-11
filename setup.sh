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
sleep 2

echo -e "${gf}INSTALANDO RCLONE...${r}"
{

[ -e /usr/bin/rclone ] && echo "${gb}${bf} Rclone Existe ⚡️${r}" || bash <(curl https://rclone.org/install.sh)

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${blf}Rclone Instalado com Sucesso!${r}   [${gb}${bb}OK${r}]"
        echo ""
    else
        echo -e "${blf}Instalação do Rclone${r}   [${gb}${bb}FALHOU${r}]"
        echo -e "${blf}Verifique o arquivo /tmp/registro.log${r}"
    fi

echo -e "${gf}INSTALANDO WO-CLI...${r}"
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

	echo -ne "${gb}${bf} Configurar o Rclone️ para google drive? [y/n] [y]:${r}" ; read -i y INS1

	if [ "$INS1" = "y" ]; then
		echo -ne "${blf}Digite o nome do seu app [gdrive]:${r} " ; read -i y NAMEAPP
    	echo -ne "${blf}Digite o ID do Cliente:${r} " ; read IDCLIENT
    	echo -ne "${blf}Digite A Chave Secreta:${r} " ; read SECRETKEY

		echo -ne "${blf}Um lInk sera gerado, copie e cole no seu browser e sigua as intruções:${r} "

		rclone config create $NAMEAPP drive cliente_id $IDCLIENT client_secret $SECRETKEY config_is_local false scope drive.file

	
	else
		echo -e "${blf}${wb} Para configurar manualmente sua app para backup \nUse: rclone config${r}"
	fi
	

	(crontab -l; echo "0 2 * * * /usr/local/bin/wo-cli -b 2> /dev/null 2>&1") | crontab -

	rm -rf $HOME/setup.sh