#!/usr/bin/env bash


clear
sleep 2
	
echo "INSTALANDO RCLONE..."
    [ -e /usr/bin/rclone ] && echo "Rclone Existe ⚡️" || curl https://rclone.org/install.sh | sudo bash

echo "INSTALANDO WO-CLI.."
    if [ -e /usr/local/bin/wo-cli ]; then
		rm -rf /usr/local/bin/wo-cli
		wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
		chmod +x /usr/local/bin/wo-cli
		else
		wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
		chmod +x /usr/local/bin/wo-cli
	fi

echo "Rclone e WO-CLI instalados"

(crontab -l; echo "0 2 * * * bash /usr/local/bin/wo-cli -b >> /var/log/wo-cli.log 2>&1") | crontab -

rm -rf $HOME/setup.sh
