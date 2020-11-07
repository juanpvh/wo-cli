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
# Version 1.0 - 2019-07-26
# -------------------------------------------------------------------------

###subindo variaveis
source /usr/local/bin/wo-cli-var.sh

#clear
cd ~

##################################
# Fucoes
##################################

_help() {
echo "Usage: wo-cli (ARGUMENTS...)
	-a <site name> 	: Backup de apenas um site.
	-b              : Backup de todos os sites.
	-c <site name>  : Restaura um site
	-d              : Restaura todos os sites.
	-e              : Configura wo-cli
	-i              : Configura o rclone para google-drive # primeira etapa
	-u              : Update do script.
	-v              : Version
	-h              : Mostra as messagens de help."
exit 1
}

#wo-cli config
_woconfig() {
	echo -ne "Digite o Nome da Pasta Onde ficara os BackUps: " ; read DIR 
	sed -i "s/BACKUPS=.*/BACKUPS=$DIR/" /usr/local/bin/wo-cli-var
	echo -ne "Digite o valor em dias que ira manter os Backups: " ; read DAYBR 
	sed -i "s/VALORDAY=.*/VALORDAY=$DAYBR/" /usr/local/bin/wo-cli-var
}

#Config rclone
_rcloneconfig() {
echo -ne "Configurar o Rclone️ para google drive! [y/n] [y]: "; read -i y INS1
if [ "$INS1" = "y" ]; then
	echo -ne "Digite o nome do seu app [gdrive]: "; read -i gdrive NAMEAPP
	echo -ne "Digite o ID do Cliente: " ; read IDCLIENT
	echo -ne "Digite A Chave Secreta: " ; read SECRETKEY
	echo "Um lInk sera gerado, copie e cole no seu browser e sigua as intruções:"
	rclone config create $NAMEAPP drive cliente_id $IDCLIENT client_secret $SECRETKEY config_is_local false scope drive.file
	else
	echo "Para configurar manualmente sua app para backup \nUse: rclone config"
	echo ""
fi
}
#update
_update() {
	echo "Fazendo Update do wo-cli..."
	mv /usr/local/bin/wo-cli /usr/local/bin/wo-cli-old
	wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
	chmod +x /usr/local/bin/wo-cli
	echo "👉  Update Concluido!!! "
}


#Deletanando arquivos antigos
old_arquivos() {
	echo "👉  Deletando arquivos com mais de 30 dias..."
	rclone --min-age "$DAYSKEEP"d --drive-use-trash=false delete $HOSTCLONE:$BACKUPS/$HOST/$SITE/
}

# Backup Single Site.
backup_single() {
	echo "——————————————————————————————————"
	wo site list
	echo "——————————————————————————————————"
	echo -ne "👉  Insira o NOME DO SITE único para fazer backup. [E.g. site.tld]: " ; read SITE

	echo "👉  Site $SITE "
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

	#deletando arquivos antigos de backup
	old_arquivos
	
	echo "👉  Corrigindo permissoes: $SITE..."		
	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} \; && find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} \;
	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Permissoes Corrigidas"
	fi

	echo "🔥 $SITE Backup Completo!"

	#Limpando pasta de backup local
	rm -rf $BACKUPPATH/$SITE

	else

	echo "🔥  $SITE NÃO EXISTE!"
	exit 1

fi
}

# Backup All.
backup_all() {

for SITE in ${SITELIST[@]}; do

	echo "⚡${gb}${bf}️  Backup do Site: $SITE...${r}"
		if [ ! -e $BACKUPPATH/$SITE ]; then
			mkdir -p $BACKUPPATH/$SITE
		fi		

	echo "👉  Criando BD para Backup: $SITE..."
	wp db repair --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1	
	wp db optimize --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1 	
	wp db export $SITE_PATH/$SITE/$SITE.sql --path=$SITE_PATH/$SITE/htdocs --allow-root >> /var/log/wo-cli.log 2>&1

	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, BD Criado!"
	fi

	echo "👉  Criando Arquivo ZIP para backup: $SITE..."
	cd $SITE_PATH/$SITE/
	tar -I pigz -cf $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz .
	rm $SITE_PATH/$SITE/$SITE.sql
	if [ "$?" -eq "0" ]; then echo "🔥 Sucesso, Arquivo ZIP Criado!"; fi

	echo "👉  Upando os Arquivos e BD na Nuvem: $SITE..."
	rclone copy $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz $HOSTCLONE:$BACKUPS/$HOST/$SITE/

	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Arquivo enviado para Nuvem!"
	fi

	#deletando arquivos antigos de backup
	old_arquivos
	
	echo "👉  Corrigindo permissoes: $SITE..."		
	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} \; && find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} \;
	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Permissoes Corrigidas"
	fi
	
	echo "🔥 $SITE Backup Completo!"
	#Limpando pasta de backup local
	rm -rf $BACKUPPATH/$SITE

done
}

#single-restore
restore_single() {

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

		echo "👉  Corrigindo permissoes: $SITE..."		
		chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
		find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} \; && find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} \;
		if [ "$?" -eq "0" ]; then
		echo "🔥 Sucesso, Permissoes Corrigidas"
		fi

		echo "⏲  Limpando pasta local..."
		#Limpando pasta de backup local
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

		echo "👉  Corrigindo permissoes: $SITE..."		
		chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
		find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} \; && find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} \;
		if [ "$?" -eq "0" ]; then
		echo "🔥 Sucesso, Permissoes Corrigidas"
		fi

		echo "⏲  Limpando pasta local..."
		#Limpando pasta de backup local
		rm -rf $BACKUPPATH/$SITE/

		echo "——————————————————————————————————"		
		echo "🔥  $SITE Restaurado!"
		echo "——————————————————————————————————"

fi 
fi


}

#MULTI-restore
restore_all() {

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

	echo "👉  Corrigindo permissoes: $SITE..."		
	chown -R www-data:www-data $SITE_PATH/$SITE/htdocs/
	find $SITE_PATH/$SITE/htdocs/ -type f -exec chmod 644 {} \; && find $SITE_PATH/$SITE/htdocs/ -type d -exec chmod 755 {} \;
	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Permissoes Corrigidas"
	fi

	echo "⏲  Limpando pasta local..."
	#Limpando pasta de backup local
	rm -rf $BACKUPPATH/$SITE/

	echo "——————————————————————————————————"		
	echo "🔥  $SITE Restaurado!"
	echo "——————————————————————————————————"
done
}


###
OPTERR=0
while getopts abcdeiuhv OPTION; do
	###
	case $OPTION in
	#executando as funções
	'a') backup_single;;
	'b') backup_all;;
	'c') restore-single;;
	'd') restore-all;;
	'e') _woconfig;;
	'i') _rcloneconfig;;
	'h') _help;;
	'u') _update;;
	'v') echo "wo-cli 1.1.0 - (C) 2019-2020 juanpvh"; exit 1;;
	'?') _help; exit 1;;
	esac
done
#FIM