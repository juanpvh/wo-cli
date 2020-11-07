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

# Colors.
#
# colors from tput
# http://stackoverflow.com/a/20983251/950111
# Usage:
# echo "${redb}red text ${gb}green text${r}"
gb=`tput setab 2` # set background green
gf=`tput setaf 2` # set background green
r=`tput sgr0`     # r to defaults


##################################
# Variaveis Global
##################################
#quantidade de dias para manter o backup
VALORDAY=30
DAYSKEEP="$(expr $VALORDAY + 1)"
BACKUPS="$USER"
HOSTCLONE=$(tail /root/.config/rclone/rclone.conf | head -n 1 | sed 's/.$//; s/.//')
HOST=$(hostname -f)
BACKUPPATH=/opt/BKSITES
DATE=$(date +"%T"."%d-%m-%Y")
SITELIST=$(ls -1L /var/www -I22222 -Ihtml)
SITE_PATH=/var/www