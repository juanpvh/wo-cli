#!/usr/bin/env bash


clear
sleep 2
FQDN=$(hostname -d)
	
echo -e "INSTALANDO RCLONE..."
{

[ -e /usr/bin/rclone ] && echo "Rclone Existe ⚡️" || bash <(curl https://rclone.org/install.sh)

} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "Rclone Instalado com Sucesso!   [OK]"
        echo ""
    else
        echo -e "Instalação do Rclone   [FALHOU]"
        echo -e "Verifique o arquivo /tmp/registro.log"
    fi

echo -e "$INSTALANDO WO-CLI.."
{

[ -e /usr/local/bin/wo-cli ] && echo "wo-cli Existe ⚡️" || wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
 chmod +x /usr/local/bin/wo-cli
} >> /tmp/registro.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "wo-cli Instalado com Sucesso!   [OK]"
        echo ""
    else
        echo -e "Instalação do WO-CLI   [FALHOU]"
        echo -e "Verifique o arquivo /tmp/registro.log"
    fi
	echo "Rclone e WO-CLI instalados"
	echo
	echo -ne "Configurar o Rclone️ para google drive? [y/n] [y]: "; read -i n INS1

	if [ "$INS1" = "y" ]; then
		echo -ne "Digite o nome do seu app [gdrive]: "; read -i gdrive NAMEAPP
    	echo -ne "Digite o ID do Cliente: " ; read IDCLIENT
    	echo -ne "Digite A Chave Secreta: " ; read SECRETKEY

		echo -ne "Um lInk sera gerado, copie e cole no seu browser e sigua as intruções:"

		rclone config create $NAMEAPP drive cliente_id $IDCLIENT client_secret $SECRETKEY config_is_local false scope drive.file

	
	else
		echo -e "Para configurar manualmente sua app para backup \nUse: rclone config"
        echo ""
	fi
	
	(crontab -l; echo "0 2 * * * bash /usr/local/bin/wo-cli -b >> /var/log/wo-cli.log 2>&1") | crontab -

	rm -rf $HOME/setup.sh