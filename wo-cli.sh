#!/usr/bin/env bash
# -------------------------------------------------------------------------
# Bash script WO-CLI
# Varias ferramentas em um script
# -------------------------------------------------------------------------
# Website:       https://
# GitHub:        https://github.com/juanpvh/wo-cli
# Copyright (c) 2019 ServicoDigital <contato@servicodigital.com.br>
# This script is licensed under M.I.T
# -------------------------------------------------------------------------
# Version 1.0.0 - 2019-07-26
# -------------------------------------------------------------------------

# Colors.
#
# colors from tput
# http://stackoverflow.com/a/20983251/950111
# Usage:
# echo "${redb}red text ${gb}green text${r}"
gb=`tput setab 2` # set background green
gf=`tput setaf 2` # set background green
r=`tput sgr0`     # r to defaults

clear
cd ~

##################################
# Variaveis Global
##################################
#quantidade de dias para manter o backup
DAYSKEEP=30
BACKUPS=BK
HOSTCLONE=$(tail /root/.config/rclone/rclone.conf | head -n 1 | sed 's/.$//; s/.//')
HOST=$(hostname -f)
BACKUPPATH=/opt/BKSITES
DATE=$(date +"%Y-%m-%d"."%T")
DAYSKEPT=$(date +"%Y-%m-%d" -d "-$DAYSKEEP days")
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITE_PATH=/var/www



##################################
# Fucoes
##################################

_help() {

echo "Usage: usage: wo-cli (sub-commands ...) {arguments ...}
       -a <site name> 	: Backup de apenas um site.
       -b				: Backup de todos os sites.
       -c <site name>	: Restaura um site
       -d				: Restaura todos os sites.
       -u				: Update do script.
	   -h				: Mostra as messagens de help."
    exit 1
}

# Backup Single Site.
backup_single ()
{
	echo "——————————————————————————————————"
	wo site list
	echo "——————————————————————————————————"
	echo -ne "👉  Insira o NOME DO SITE único para fazer backup. [E.g. site.tld]: " ; read SITE

	echo -ne "👉  Site $SITE "

	if [ -d "$SITE_PATH/$SITE" ] ; then

	echo "⚡ ${gb}${bf}Backup do site: $SITE...${r}"

	mkdir -p $BACKUPPATH/$SITE

	echo "👉  Criando BD para Backup: $SITE..."

	wp db repair --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1
	wp db optimize --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1
	wp db export $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1

	echo "👉  Criando Arquivos para backup: $SITE..."

	cd $SITE_PATH/$SITE/
	tar -I pigz -cf $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz .
	rm $SITE_PATH/$SITE/$SITE.sql

	echo "👉  Upando os Arquivos e BD na Nuvem: $SITE..."

	rclone copy $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz $HOSTCLONE:$BACKUPS/$HOST/$SITE/
	DELLSITE=$(rclone ls $HOSTCLONE:$BACKUPS/$HOST/$SITE | grep -E $DAYSKEPT.*.$SITE.tar.gz | awk '{print $2}')
	if [ ! -z "$DELLSITE" ]; then		
		rclone deletefile $HOSTCLONE:$BACKUPS/$HOST/$SITE/$DELLSITE --drive-use-trash=false
	fi

	echo "👉  Corrindo permissoes: $SITE..."

	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +	

	echo "🔥 $SITE Backup Completo!"

	rm -rf $BACKUPPATH/$SITE

	else

	echo "🔥  $SITE NÃO EXISTE!"
	exit 1

fi
}

# Backup All.
backup_all ()
{

for SITE in ${SITELIST[@]}; do

	echo "⚡${gb}${bf}️  Backup do Site: $SITE...${r}"


		if [ ! -e $BACKUPPATH/$SITE ]; then
			mkdir -p $BACKUPPATH/$SITE
		fi		

	echo "👉  Criando BD para Backup: $SITE..."

	wp db repair --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1	
	wp db optimize --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1 	
	wp db export $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1 
	if [ "$?" -eq "0" ]; then echo "🔥 Sucesso, BD Criado!"; fi
	echo "👉  Criando Arquivo ZIP para backup: $SITE..."
	cd $SITE_PATH/$SITE/
	tar -I pigz -cf $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz .
	rm $SITE_PATH/$SITE/$SITE.sql
	if [ "$?" -eq "0" ]; then echo "🔥 Sucesso, Arquivo ZIP Criado!"; fi

	echo "👉  Upando os Arquivos e BD na Nuvem: $SITE..."

	rclone copy $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz $HOSTCLONE:$BACKUPS/$HOST/$SITE/ 
	if [ "$?" -eq "0" ]; then echo "🔥 Sucesso, ZIP enviado para Nuvem!"; fi
	DELLSITE=$(rclone ls $HOSTCLONE:$BACKUPS/$HOST/$SITE/ | grep -E $DAYSKEPT.*.$SITE.tar.gz | awk '{print $2}')  
	if [ ! -z "$DELLSITE" ]; then		
		rclone deletefile $HOSTCLONE:$BACKUPS/$HOST/$SITE/$DELLSITE --drive-use-trash=false
	fi
	rm -rf $BACKUPPATH/$SITE

	echo "👉  Corrigindo permissoes: $SITE..."
		
	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +
	if [ "$?" -eq "0" ]; then echo "🔥 Sucesso, Permissoes Corrigidas"; fi
	
	echo "🔥 $SITE Backup Completo!"

done
}

#single-restore
single_restore () {

	echo "——————————————————————————————————"
	wo site list
	echo "——————————————————————————————————"
	echo -ne "👉 Insira o NOME DO SITE único para Restaurar. [E.g. site.tld]: " ; read SITE
	echo "——————————————————————————————————"

	if [ -e "$SITE_PATH/$SITE" ] ; then
		echo "Por Padrao ira restaurat o ultimo backup realizado!"
		echo -ne "Restaurar Backup de Datas Anteriores? [y,n]: " ; read -i n INS1

	if [ "$INS1" = "y" ]; then

		echo "⚡️  Listando Backups Existentes:"

		rclone ls  $HOSTCLONE:$BACKUPS/$HOST/$SITE/ | awk '{print $2}'

		echo -ne "Digite o Nome do Backup a ser Restaurado: " ; read -i y REST
		echo "⚡️  Fazendo Download para Pasta Local..."
		
		rm -rf $BACKUPPATH/$SITE/
		rclone copy $HOSTCLONE:$BACKUPS/$HOST/$SITE/$REST $BACKUPPATH/$SITE/

		echo "⚡️  Download Realizado do site: $SITE ..."

		echo "⏲  Extraindo o backup..."

		tar -xzf $BACKUPPATH/$SITE/$REST -C $BACKUPPATH/$SITE/
		rm -rf $BACKUPPATH/$SITE/{$REST,backup,conf,logs,wp-config.php}

		echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
		
		rm -rf $SITE_PATH/$SITE/htdocs

		echo "Arquivos extraidos"
		echo "⏲  Restaurando arquivos e  Banco de Dados.."

		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/htdocs $SITE_PATH/$SITE
		wp db reset --yes --allow-root --path=$SITE_PATH/$SITE/htdocs/ >> /var/log/wo-cli.log 2>&1
		wp db import $BACKUPPATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs/ --allow-root >> /var/log/wo-cli.log 2>&1

		echo "⏲  Fixando permissões..."

		sudo chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
		sudo find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
		sudo find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +

		echo "⏲  Limpando pasta local..."

		rm -rf $BACKUPPATH/$SITE

		echo "——————————————————————————————————"		
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"

	else
		rm -rf $BACKUPPATH/$SITE/
		ULTIMO=$(rclone ls  $HOSTCLONE:$BACKUPS/$HOST/$SITE/ | head -n 1 | awk '{print $2}')
		
		echo "⚡️  Fazendo Download para Pasta Local..."

		rclone copy $HOSTCLONE:$BACKUPS/$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
		
		echo "⚡️  Download Realizado do site: $SITE ..."
		echo "⏲  Removendo os arquivos do site atual..."

		rm -rf $SITE_PATH/$SITE/htdocs

		echo "⏲  Extraindo o backup..."

		tar -xzf $BACKUPPATH/$SITE/$ULTIMO -C $BACKUPPATH/$SITE/
		rm -rf $BACKUPPATH/$SITE/{$ULTIMO,backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"
		echo
		echo "⏲  Restaurando arquivos e  Banco de Dados.."

		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/htdocs $SITE_PATH/$SITE
		wp db reset --yes --allow-root --path=$SITE_PATH/$SITE/htdocs/ >> /var/log/wo-cli.log 2>&1
		wp db import $BACKUPPATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs/ --allow-root >> /var/log/wo-cli.log 2>&1

		echo "⏲  Fixando permissões..."

		sudo chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
		sudo find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
		sudo find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +

		echo "⏲  Limpando pasta local..."

		rm -rf $BACKUPPATH/$SITE/

		echo "——————————————————————————————————"		
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"

fi 
fi


}

#MULTI-restore
multi_restore() {

# INCIANDO O LOOP.
for SITE in ${SITELIST[@]}; do
	echo "⚡️  Iniciando Restauração do site: $SITE ..."
	rm -rf $BACKUPPATH/$SITE/
	ULTIMO=$(rclone ls  $HOSTCLONE:$BACKUPS/$HOST/$SITE/ | head -n 1 | awk '{print $2}')
	
	echo "⚡️  Fazendo Download para Pasta Local..."

	rclone copy $HOSTCLONE:$BACKUPS/$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
		
	echo "⚡️  Download Realizado do site: $SITE ..."
	echo "⏲  Removendo os arquivos do site atual..."

	rm -rf $SITE_PATH/$SITE/htdocs

	echo "⏲  Extraindo o backup..."

	tar -xzf $BACKUPPATH/$SITE/$ULTIMO -C $BACKUPPATH/$SITE/
	rm -rf $BACKUPPATH/$SITE/{$ULTIMO,backup,conf,logs,wp-config.php}

	echo "Arquivos extraidos"
	echo
	echo "⏲  Restaurando arquivos e  Banco de Dados.."

	rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/htdocs $SITE_PATH/$SITE
	wp db reset --yes --allow-root --path=$SITE_PATH/$SITE/htdocs/ >> /var/log/wo-cli.log 2>&1
	wp db import $BACKUPPATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs/ --allow-root >> /var/log/wo-cli.log 2>&1

	echo "⏲  Fixando permissões..."

	sudo chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	sudo find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
	sudo find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Limpando pasta local..."

	rm -rf $BACKUPPATH/$SITE/

	echo "——————————————————————————————————"		
	echo "🔥  $SITE Restaurado!"
	echo "——————————————————————————————————"
done
}






###
OPTERR=0
while getopts abcduh OPTION
do

###
	case $OPTION in
		#executando as funções
		'a') backup_single	                  ;;
		'b') backup_all		                  ;;
		'c') single_restore                   ;;
		'd') multi_restore                    ;;
		'u') update                           ;;	
		'h') _help                            ;;
		'?') _help; exit 1;;
	esac
done
#FIM
