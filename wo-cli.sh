#!/usr/bin/env bash
# -------------------------------------------------------------------------
# Bash script WO-CLI
# Varias ferramentas em um script
# -------------------------------------------------------------------------
# Website:       https://
# GitHub:        https://github.com/juanpvh/wo-cli
# Copyright (c) 2019 ServicoDigital <juancm_pvh@hotmail.com>
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

clear
cd ~

##################################
# Variaveis Global
##################################

HOST=$(hostname)
BACKUPPATH=~/opt/backup
DATE=$(date +"%Y-%m-%d")
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITE_PATH=/var/www


	if [ ! -e "$BACKUPPATH" ]; then
		mkdir -p $BACKUPPATH
	fi

##################################
# Fucoes
##################################

_help() {

echo "Usage: wo-cli (sub-commands ...) {arguments ...}
       -a <site name> 	: Backup de todos os sites.
	   -h				: Mostra as messagens de help."
    exit 3
}



# Backup All.
backup_all()
{

for SITE in ${SITELIST[@]}; do
	echo "——————————————————————————————————"
	echo "⚡️  Backup do Site: $SITE..."
	echo "——————————————————————————————————"

		if [ ! -e $BACKUPPATH/$SITE ]; then
			mkdir -p $BACKUPPATH/$SITE
		fi		

	echo "⏲  Criando BD para Backup: $SITE..."

	wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs

	echo "⏲  Criando Arquivos para backup: $SITE..."

	tar -I pigz -cf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
	rm $SITE_PATH/$SITE/$SITE.sql

	echo "⏲  Corrindo permissoes: $SITE..."
		
	chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
	find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Upando os Arquivos e BD na Nuvem: $SITE..."

	restic -r $RESTIC_REPOSITORY/backup $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz
	restic -r $RESTIC_REPOSITORY/backup forget --keep-last 30 --prune
		
	rm -rf $BACKUPPATH/$SITE

	echo "🔥 Backup do $SITE Enviado!"

done
}

echo "🔥 Backup Completo de todos os sites!"


OPTERR=0

while getopts ah OPTION
do

###
	case $OPTION in
		#executando as funções
		'a') backup_all		;;
		'h') _help			;;
		'?') _help; exit 1  ;;
	esac
done
#FIM
	
	
	