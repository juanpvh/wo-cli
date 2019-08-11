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
BACKUPPATH=~/opt/backup
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
    cat <<EOT
    Usage: $PROGRAM OPTIONS < -b <build> | -s <server> >
        One of the following commands are required:
      * -b|--build <build>   : The 4-digit release printed on the DVD (required)
      * -s|--server <server> : Use <server> for NCOA image (assumes Rsync mode)
        And any combination of the following OPTIONS are optional:
        -c|--clean           : Run the ncoa_clean.sh script prior to install
        -f|--force           : Force the install regardless of current status
                               (use this to restart a bad install)
        -h|--help            : Print this help message.
        -t|--test            : Run tests even if already installed
        --notest             : Do not run tests
        -v|--verbose         : Provide more feedback (may be given more than once)
        -V|--version         : Display the program version and exit
    * Required
EOT
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

	wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs

	echo "⏲  Criando Arquivos para backup: $SITE..."

	tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
	rm $SITE_PATH/$SITE/$SITE.sql

	echo "⏲  Corrindo permissoes: $SITE..."
		
	chown -R www-data:www-data $SITESTORE/$SITE/htdocs/
	find $SITESTORE/$SITE/htdocs/ -type f -exec chmod 644 {} +
	find $SITESTORE/$SITE/htdocs/ -type d -exec chmod 755 {} +

	echo "⏲  Upando os Arquivos e BD na Nuvem: $SITE..."

	rclone copy $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/

	DELLSITE=$(rclone ls $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE | grep -E $DAYSKEPT.$SITE.tar.gz | awk '{print $2}')
	if [ ! -f $DELLSITE ]; then		
		rclone deletefile $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$DELLSITE.$SITE.sql.gz
	fi
		
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
		echo -ne "Restaurar do Ultimo BackUp existente (y) ou escolher por Data (n): " ; read -i y INS1

	if [ "$INS1" = "n" ]; then

		echo "⚡️  Listando Backups Existentes: $SITE..."
		rclone ls  $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/ | awk '{print $2}'
		echo -ne "Digite o Nome do Backup a ser Restaurado: " ; read -i y RESTBACK
		echo "⚡️  Fazendo Download para Pasta Local..."
		echo
		time rclone copy $HOSTCLONE:BACKUP-SITES/SERVERS-$HOST/$SITE/$RESTBACK $BACKUPPATH/$SITE/
		echo "⚡️  Download Realizado do site: $SITE ..."

		#FAZENDO BACKUP DE SEGUNRANÇA DO SITE ATUAL ANTES DE RESTAURAR		
		wp db export $SITE_PATH/$SITE/$SITE.sql --allow-root --path=$SITE_PATH/$SITE/htdocs
		tar -czf $BACKUPPATH/$SITE/$DATE-$SITE.tar.gz $SITE_PATH/$SITE/
		rm $SITE_PATH/$SITE/$SITE.sql
		
		echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
		rm -rf $SITESTORE/$SITE/htdocs

		echo "⏲  Extraindo o backup..."
		
		tar -xzf $BACKUPPATH/$SITE/$RESTBACK -C $BACKUPPATH/$SITE/
		rm -rf $BACKUPPATH/$SITE/$RESTBACK/{backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"
		echo "⏲  Restaurando arquivos e  Banco de Dados.."

		rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE/* $SITESTORE/$SITE_NAME

		echo "⏲  Restaurando banco de dados..."

		wp db reset --yes --allow-root --path=$SITESTORE/$SITE_NAME/htdocs/ 
		wp db import $SITESTORE/$SITE/$SITE.sql --path=$SITESTORE/$SITE/htdocs/ --allow-root

		echo "⏲  Fixando permissões..."

		sudo chown -R www-data:www-data $SITESTORE/$SITE_NAME/htdocs/
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
		
		echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
		rm -rf $SITESTORE/$SITE/htdocs

		echo "⏲  Extraindo o backup..."
		
		tar -xzf $BACKUPPATH/$SITE/$RESTBACK -C $BACKUPPATH/$SITE/
		rm -rf $BACKUPPATH/$SITE/$RESTBACK/{backup,conf,logs,wp-config.php}

		echo "Arquivos extraidos"
		echo "⏲  Restaurando arquivos e  Banco de Dados.."

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
for SITE_NAME in ${SITELISTREST[@]}; do

	if [ ! -e $BACKUPPATH/$SITE_NAME ]; then
		echo "$SITE_NAME Não existe!"
	fi

	echo "——————————————————————————————————"
	echo "⚡️  Restore the site: $SITE_NAME..."
	echo "——————————————————————————————————"

	echo "——————————————————————————————————"
	echo "⚡️  Fazendo Download para Pasta Local..."
	echo "———————————————————————————————————————"

	time rclone copy $HOSTCLONE:BACKUP-SERVER-$HOST/$SITE_NAME-$DATE $BACKUPPATH/$SITE_NAME-$DATE/$SITE_NAME-$DATE.tar.gz 
	time rclone copy $HOSTCLONE:BACKUP-SERVER-$HOST/$SITE_NAME-$DATE $BACKUPPATH/$SITE_NAME-$DATE/$SITE_NAME-$DATE.sql.gz

	echo "——————————————————————————————————"
	echo "⚡️  Download Realizado do site: $SITE_NAME ..."
	echo "—————————————————————————————————————————————"
		
	cd $BACKUPPATH/$SITE_NAME
	rm -rf $SITESTORE/$SITE_NAME/htdocs

	echo "——————————————————————————————————"
	echo "⏲  Removendo os arquivos do site atual e redefinindo o banco de dados..."
	echo "——————————————————————————————————"

	mkdir -p $BACKUPPATH/$SITE_NAME/files
	mkdir -p $BACKUPPATH/$SITE_NAME/db

	echo "——————————————————————————————————"
	echo "⏲  Extraindo o backup..."
	echo "——————————————————————————————————"
		
	tar -xzf $BACKUPPATH/$SITE_NAME/$SITE_NAME.tar.gz -C $BACKUPPATH/$SITE_NAME/files/
	rm -rf $BACKUPPATH/$SITE_NAME/files/{backup,conf,logs,wp-config.php}

	echo "——————————————————————————————————"
	echo "Arquivos extraidos"
	echo "——————————————————————————————————"
		
	tar -xzf $BACKUPPATH/$SITE_NAME/$SITE_NAME.sql.gz -C $BACKUPPATH/$SITE_NAME/db/ --strip-components=3
	
	echo "——————————————————————————————————"
	echo "DB extraido"
	echo "——————————————————————————————————"
	echo "⏲  Restaurando arquivos..."
	echo "——————————————————————————————————"

	rsync -azh --info=progress2 --stats --human-readable $BACKUPPATH/$SITE_NAME/files/* $SITESTORE/$SITE_NAME

	echo "——————————————————————————————————"
	echo "⏲  Restaurando banco de dados..."
	echo "——————————————————————————————————"

	wp db reset --yes --allow-root --path=$SITESTORE/$SITE_NAME/htdocs/ 
	wp db import $BACKUPPATH/$SITE_NAME/db/$SITE_NAME.sql --path=$SITESTORE/$$SITE_NAME/htdocs/ --allow-root #--dbuser=$DB_USERX --dbpass=$DB_PASSX

	echo "——————————————————————————————————"
	echo "⏲  Fixando permissões..."
	echo "——————————————————————————————————"

	sudo chown -R www-data:www-data $SITESTORE/$SITE_NAME/htdocs/
	sudo find $SITESTORE/$SITE_NAME/htdocs/ -type f -exec chmod 644 {} +
	sudo find $SITESTORE/$SITE_NAME/htdocs/ -type d -exec chmod 755 {} +

	echo "——————————————————————————————————"
	echo "⏲  Limpando pasta local..."
	echo "——————————————————————————————————"
	
	rm -rfv $BACKUPPATH/$SITE_NAME

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
		'?') echo 'Ocorreu um erro !!'; exit 1;;
	esac
done
#FIM
	
	
	