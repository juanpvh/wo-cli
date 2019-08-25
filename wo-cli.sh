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

	if [ ! -e "$BACKUPPATH" ]; then
		mkdir -p $BACKUPPATH
	fi
clear
cd ~

##################################
# Variaveis Global
##################################
#quantidade de dias para manter o backup
DAYSKEEP=30

HOSTCLONE=$(tail /root/.config/rclone/rclone.conf | head -n 1 | sed 's/.$//; s/.//')
HOST=$(hostname)
FQDN=$(hostname -d)
BACKUPPATH=~/opt/backups
DATE=$(date +"%Y-%m-%d")
DAYSKEPT=$(date +"%Y-%m-%d" -d "-$DAYSKEEP days")
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITELISTREST=$(ls -1L $BACKUPPATH/)
SITE_PATH=/var/www
RESTBAKUP=$(rclone lsl  $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE | head -n 1 | awk '{print $2,$4}')

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
    exit 3
}

# Backup Single Site.
backup-single()
{
	echo "——————————————————————————————————"
	wo site list
	echo "——————————————————————————————————"
	echo -ne "👉  Insira o NOME DO SITE único para fazer backup. [E.g. site.tld]: " ; read SITE

	if [ -e "$SITE_PATH/$SITE" ] ; then

	echo "⚡️ Backup do site: $SITE..."

	mkdir -p $BACKUPPATH/"$SITE"/

	echo "⏲  Criando BD para Backup: $SITE..."

	wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs

	echo "⏲  Criando Arquivos para backup: $SITE..."

	tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
	rm $SITE_PATH/$SITE/$SITE.sql

	echo "⏲  Corrindo permissoes: $SITE..."

	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Upando os Arquivos e BD na Nuvem: $SITE..."

	rclone copy $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/

	DELLSITE=$(rclone ls $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE | grep -E $DAYSKEPT.$SITE.tar.gz | awk '{print $2}')
	if [ ! -f $DELLSITE ]; then		
		rclone deletefile $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$DELLSITE.$SITE.sql.gz
	fi

	echo "🔥 $SITE Backup Completo!"

	rm -rf $BACKUPPATH/$SITE

	else

	echo "🔥  $SITE NÃO EXISTE!"
	exit 1

fi
}

# Backup All.
backup-all()
{

for SITE in ${SITELIST[@]}; do
	echo "——————————————————————————————————"
	echo "⚡️  Backup do Site: $SITE..."
	echo "——————————————————————————————————"

		if [ ! -e $BACKUPPATH/$SITE ]; then
			mkdir -p $BACKUPPATH/$SITE
		fi		

	echo "⏲  Criando BD para Backup: $SITE..."
	
	wp db repair $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root
	wp db optimize $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root
	wp db export $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root

	echo "⏲  Criando Arquivos para backup: $SITE..."

	tar -I pigz -cf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
	rm $SITE_PATH/$SITE/$SITE.sql

	echo "⏲  Corrindo permissoes: $SITE..."
		
	chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Upando os Arquivos e BD na Nuvem: $SITE..."
	
	restic -r rclone:$HOSTCLONE:BACKUPS:$FQDN/backups/$SITE backup -q $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz
	
	rm -rf $BACKUPPATH/$SITE

	echo "🔥 $SITE Backup Completo!"

done
}

#single-restore
single-restore() {

	echo "——————————————————————————————————"
	wo site list
	echo "——————————————————————————————————"
	echo -ne "👉 Insira o NOME DO SITE único para Restaurar. [E.g. site.tld]: " ; read SITE
	echo "——————————————————————————————————"

	if [ -e "$SITE_PATH/$SITE" ] ; then
		echo -ne "Por Padrao ira restaura o ultimo backup, escolha [ n ] para isso)!"
		echo -ne "Restaurar Backup de Datas Anteriores? [y,n]: " ; read -i n INS1

	if [ "$INS1" = "n" ]; then

		echo "⚡️  Listando Backups Existentes:"

		rclone ls  $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/ | awk '{print $2}'

		echo -ne "Digite o Nome do Backup a ser Restaurado: " ; read -i y REST
		echo "⚡️  Fazendo Download para Pasta Local..."

		rclone copy $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$REST $BACKUPPATH/$SITE/

		echo "⚡️  Download Realizado do site: $SITE ..."

		#FAZENDO BACKUP DE SEGUNRANÇA DO SITE ATUAL ANTES DE RESTAURAR		
		wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs
		tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
		rm $SITE_PATH/$SITE/$SITE.sql
		
		echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
		
		rm -rf $SITESTORE/$SITE/htdocs

		echo "⏲  Extraindo o backup..."
		
		tar -xzf $BACKUPPATH/$SITE/$REST -C $BACKUPPATH/$SITE/
		rm -rf $BACKUPPATH/$SITE/$REST/{backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"
		echo "⏲  Restaurando arquivos e  Banco de Dados.."

		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/* $SITESTORE/$SITE

		echo "⏲  Restaurando banco de dados..."

		wp db reset --yes --allow-root --path=$SITESTORE/$SITE/htdocs/ 
		wp db import $SITESTORE/$SITE/$SITE.sql --path=$SITESTORE/$SITE/htdocs/ --allow-root

		echo "⏲  Fixando permissões..."

		sudo chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
		sudo find $SITESTORE/$SITE_NAME/htdocs/ -type f -exec chmod 644 {} +
		sudo find $SITESTORE/$SITE_NAME/htdocs/ -type d -exec chmod 755 {} +

		echo "⏲  Limpando pasta local..."

		rm -rfv $BACKUPPATH/$SITE

		echo "——————————————————————————————————"		
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"

	else
		ULTIMO=$(rclone ls  $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/ | head -n 1 | awk '{print $2}')

		echo "⚡️  Fazendo Download para Pasta Local..."
		echo
		time rclone copy $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
		echo "⚡️  Download Realizado do site: $SITE ..."

		#FAZENDO BACKUP DE SEGUNRANÇA DO SITE ATUAL ANTES DE RESTAURAR		
		wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs
		tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
		rm $SITE_PATH/$SITE/$SITE.sql
		
		echo "⏲  Removendo os arquivos do site atual..."

		rm -rf $SITESTORE/$SITE/htdocs

		echo "⏲  Extraindo o backup..."

		tar -xzf $BACKUPPATH/$SITE/$RESTBACK -C $BACKUPPATH/$SITE/		
		rm -rf $BACKUPPATH/$SITE/$RESTBACK/{backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"
		echo "⏲  Restaurando arquivos..."

		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/* $SITESTORE/$SITE

		echo "⏲  Restaurando banco de dados..."

		wp db reset --yes --allow-root --path=$SITESTORE/$SITE/htdocs/ 
		wp db import $SITESTORE/$SITE/$SITE.sql --path=$SITESTORE/$SITE/htdocs/ --allow-root

		echo "⏲  Fixando permissões..."

		sudo chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
		sudo find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
		sudo find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

		echo "⏲  Limpando pasta local..."

		rm -rfv $BACKUPPATH/$SITE

		echo "——————————————————————————————————"		
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"

fi 
fi


}

#single-restore
multi-restore() {

# INCIANDO O LOOP.
for SITE in ${SITELIST[@]}; do

	ULTIMO=$(rclone ls  $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/ | head -n 1 | awk '{print $2}')

	echo "⚡️  Fazendo Downloado site: $SITE para Pasta Local..."
	time rclone copy $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
	echo "⚡️  Download Realizado do site: $SITE ..."
	
	#FAZENDO BACKUP DE SEGUNRANÇA DO SITE ATUAL ANTES DE RESTAURAR		
	wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs
	tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
	rm $SITE_PATH/$SITE/$SITE.sql
	
	echo "⏲  Removendo os arquivos do site atual..."

	rm -rf $SITESTORE/$SITE/htdocs

	echo "⏲  Extraindo o backup..."

	tar -xzf $BACKUPPATH/$SITE/$RESTBACK -C $BACKUPPATH/$SITE/		
	rm -rf $BACKUPPATH/$SITE/$RESTBACK/{backup,conf,logs,wp-config.php}

	echo "Arquivos extraidos"
	echo "⏲  Restaurando arquivos..."

	rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/* $SITESTORE/$SITE
	echo "⏲  Restaurando banco de dados..."

	wp db reset --yes --allow-root --path=$SITESTORE/$SITE/htdocs/ 
	wp db import $SITESTORE/$SITE/$SITE.sql --path=$SITESTORE/$SITE/htdocs/ --allow-root

	echo "⏲  Fixando permissões..."

	sudo chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
	sudo find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
	sudo find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Limpando pasta local..."

	rm -rfv $BACKUPPATH/$SITE

	echo "——————————————————————————————————"		
	echo "🔥  $SITE Restaurado!"
	echo "——————————————————————————————————"
done
}






###
OPTERR=0

while getopts a:bc:drh OPTION
do

###
	case $OPTION in
		#executando as funções
		'a') SITE_NAME="$OPTARG" 
			 single-backup	                  ;;
		'b') all-backup		                  ;;
		'c') SITE_NAME="$OPTARG" 
			 single-restore                   ;;
		'd') multi-restore                    ;;
		'u') update                           ;;	
		'h') _help                            ;;
		'?') _help; exit 1;;
	esac
done
#FIM
	
	
	