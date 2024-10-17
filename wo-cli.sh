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
# Version 2.3.0 - 17-10-2024
# -------------------------------------------------------------------------

###variaveis

VALORDAY=29
DAYSKEEP="$(expr $VALORDAY + 1)"
BACKUPS_DIR=


HOSTCLONE=$(tail /root/.config/rclone/rclone.conf | head -n 1 | sed 's/.$//; s/.//')
HOST=$(hostname -f)
BACKUPPATH=/opt/BKSITES
DATE=$(date +"%d-%m-%Y"."%T")
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITE_PATH=/var/www

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
	-f              : Deletando Backups Antigos
	-g              : Configura o rclone para google-drive # primeira etapa
	-i              : Quantidade de backup(s) por site(s)
	-j              : Quantidade de hits por url, salvo no backup 
	-u              : Update do script.
	-v              : Version
	-h              : Mostra as messagens de help.
	Lista de templates: tb_noticias tb_saude tb_adulto tb_tecnologia"
exit 1
}

_restore_template() {
    echo "Restaurando template"
    
    # Verificar se foram fornecidos os argumentos necessários
    if [ $# -ne 2 ]; then
        echo "Uso: wo-cli -l <dominio> <template_backup>"
        exit 1
    fi

    DOMINIO=$1
    TEMPLATE=$2
    TEMPLATE_DIR="/opt/BKSITES/TEMPLATE"
    
    # Criar diretório para o template se não existir
    mkdir -p $TEMPLATE_DIR

    echo "Baixando template $TEMPLATE do Google Drive..."
	rclone copy $HOSTCLONE:$BACKUPS_DIR/TEMPLATE/$TEMPLATE.tar.gz $TEMPLATE_DIR/

    if [ ! -f "$TEMPLATE_DIR/$TEMPLATE.tar.gz" ]; then
        echo "Erro: Template $TEMPLATE não encontrado no Google Drive."
        exit 1
    fi

    echo "Extraindo template..."
    tar -xzf $TEMPLATE_DIR/$TEMPLATE.tar.gz -C $TEMPLATE_DIR

	echo "Limpando arquivos da pasta htdocs..."
	rm -rf $SITE_PATH/$DOMINIO/htdocs/*

    echo "Restaurando template para o domínio $DOMINIO..."
    rsync -azh --delete $TEMPLATE_DIR/htdocs/* $SITE_PATH/$DOMINIO/htdocs/

    echo "Atualizando URLs no banco de dados..."
    wp search-replace "http://template.com" "https://$DOMINIO" --path=$SITE_PATH/$DOMINIO/htdocs --all-tables --allow-root
    wp search-replace "https://template.com" "https://$DOMINIO" --path=$SITE_PATH/$DOMINIO/htdocs --all-tables --allow-root

	echo "Atualizando wordpress..."
	wp core update --path=$SITE_PATH/$DOMINIO/htdocs --allow-root

    echo "Corrigindo permissões..."
    chown -R www-data:www-data $SITE_PATH/$DOMINIO/htdocs/
    find $SITE_PATH/$DOMINIO/htdocs/ -type f -exec chmod 644 {} \;
    find $SITE_PATH/$DOMINIO/htdocs/ -type d -exec chmod 755 {} \;

    echo "Limpando diretório temporário..."
    rm -rf $TEMPLATE_DIR

    echo "Template $TEMPLATE restaurado com sucesso para o domínio $DOMINIO!"
}

#wo-cli config
_woconfig() {
	echo -ne "Digite o Nome da Pasta Onde ficara os BackUps: " ; read DIR 
	sed -i "s/BACKUPS_DIR=.*/BACKUPS_DIR=$DIR/" /usr/local/bin/wo-cli
	echo -ne "Digite o valor em dias que ira manter os Backups: " ; read DAYBR 
	sed -i "s/VALORDAY=.*/VALORDAY=$DAYBR/" /usr/local/bin/wo-cli
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
	rm -rf /usr/local/bin/wo-cli
	VAR1=$(sed -n "/^BACKUPS_DIR/p" /usr/local/bin/wo-cli-old)
	wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
#	sed -i "s/BACKUPS_DIR=.*/$VAR1/" /usr/local/bin/wo-cli
	sed -i "/BACKUPS_DIR=.*/{ s/BACKUPS_DIR=.*/$VAR1/;:a;n;ba }" /usr/local/bin/wo-cli
	chmod +x /usr/local/bin/wo-cli
	rm -rf /usr/local/bin/wo-cli-old
	echo "👉  Update do wo-cli Concluido!!! "
}

#Deletanando arquivos antigos
old_arquivos() {
	echo "👉  Deletando arquivos com mais de $DAYSKEEP dias..."
for SITE in ${SITELIST[@]}; do
	rclone --min-age "$DAYSKEEP"d --drive-use-trash=false delete $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/
	QUANT=$(rclone ls $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/ | wc -l)
	echo "Quantidade de Backup SITE: $SITE = $QUANT"
done
}

#Quantidade de backups por site
quant_backs() {
	echo "👉  Quantidade de backups por site..."
for SITE in ${SITELIST[@]}; do
    QUANT=$(rclone ls $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/ | wc -l)
    echo "$QUANT = $SITE"
done
}

_access() {


rm -rf $HOME/sites/ $HOME/posts $HOME/listposts.txt

mkdir -p $HOME/posts/
mkdir -p $HOME/sites/

for SITE in ${SITELIST[@]}; do
	wp post list --post_type=page,post  --field=url --path=/var/www/$SITE/htdocs --allow-root > $HOME/sites/$SITE
	sed -i "/$SITE/ s/https\:\/\/$SITE//g" $HOME/sites/$SITE
	sed -i "/$SITE/ s/http\:\/\/$SITE//g" $HOME/sites/$SITE
done

LIST=$(ls -1 $HOME/sites/)

for lista in ${LIST[@]}; do
	cat $HOME/sites/$lista >> listposts.txt
done 

LS=$(cat listposts.txt)

for SITE in ${SITELIST[@]}; do
for pos in ${LS[@]}; do
mkdir -p $HOME/posts/$SITE
VAR=$(grep -c  $pos /var/log/nginx/$SITE.access.log)
echo "$VAR --  $pos "  >> $HOME/posts/$SITE/$SITE.list1.log.txt
sed -i "/^0/d" $HOME/posts/$SITE/$SITE.list1.log.txt
done
done



for SITE in ${SITELIST[@]}; do
for pos in ${LS[@]}; do
mkdir -p $HOME/posts/$SITE
VAR=$(grep -c  $pos /var/log/nginx/$SITE.access.log.1)
echo "$VAR --  $pos "  >> $HOME/posts/$SITE/$SITE.list1.log1.txt
sed -i "/^0/d" $HOME/posts/$SITE/$SITE.list1.log1.txt
done
done


for SITE in ${SITELIST[@]}; do
	cat $HOME/posts/$SITE/$SITE.list1.log.txt | sort | uniq | sort -nr > $HOME/posts/$SITE/$SITE.GERAL.log.txt
    cat $HOME/posts/$SITE/$SITE.list1.log1.txt | sort | uniq | sort -nr >> $HOME/posts/$SITE/$SITE.GERAL.log.txt 
    awk 'BEGIN{FS=OFS=" -- "}; {a[$2]+=$1}; END{for (b in a){print a[b],  b}}'  $HOME/posts/$SITE/$SITE.GERAL.log.txt | sort | uniq | sort -nr > $HOME/posts/$SITE/$SITE.log.txt
    rclone copy $HOME/posts/$SITE/$SITE.log.txt $HOSTCLONE:$BACKUPS_DIR/HITS/$SITE/
done

rm -rf $HOME/sites/ $HOME/posts $HOME/listposts.txt
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
	rclone copy $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/

	#deletando arquivos antigos de backup
	echo "👉  Deletando arquivos com mais de 30 dias..."
	rclone --min-age "$DAYSKEEP"d --drive-use-trash=false delete $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/
	
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
	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Arquivo ZIP Criado!"
	fi

	echo "👉  Upando os Arquivos e BD na Nuvem: $SITE..."
	rclone copy $BACKUPPATH/$SITE/$DATE.$SITE.tar.gz $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/

	if [ "$?" -eq "0" ]; then
	echo "🔥 Sucesso, Arquivo enviado para Nuvem!"
	fi

	#deletando arquivos antigos de backup
	echo "👉  Deletando arquivos com mais de 30 dias..."
	rclone --min-age "$DAYSKEEP"d --drive-use-trash=false delete $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/
	
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
		rclone ls  $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/ | awk '{print $2}'

		echo -ne "Digite o Nome do Backup a ser Restaurado: " ; read -i y REST
		echo "⚡️  Fazendo Download para Pasta Local..."		
		rm -rf $BACKUPPATH/$SITE/
		rclone copy $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/$REST $BACKUPPATH/$SITE/

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
		ULTIMO=$(rclone ls  $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/ | head -n 1 | awk '{print $2}')
		
		echo "⚡️  Fazendo Download para Pasta Local..."
		rclone copy $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
		
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
	ULTIMO=$(rclone ls  $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/ | head -n 1 | awk '{print $2}')
	
	echo "⚡️  Fazendo Download para Pasta Local..."
	rclone copy $HOSTCLONE:$BACKUPS_DIR/$HOST/$SITE/$ULTIMO $BACKUPPATH/$SITE/
		
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
while getopts abcdefghijhluv OPTION; do
	###
	case $OPTION in
	#executando as funções
	'a') backup_single;;
	'b') backup_all;;
	'c') restore_single;;
	'd') restore_all;;
	'e') _woconfig;;
	'f') old_arquivos;;
	'g') _rcloneconfig;;
	'h') _help;;
	'i') quant_backs;;
	'j') _access;;
	'u') _update;;
	'l') _restore_template $2 $3;;
	'v') echo "wo-cli version:2.3.0 - (C) 2019-2024 juanpvh"; exit 1;;
	'?') _help; exit 1;;
	esac
done
#FIM