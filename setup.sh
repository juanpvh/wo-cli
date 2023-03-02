#!/usr/bin/env bash
	
echo "INSTALANDO RCLONE..."
    [ -e /usr/bin/rclone ] && echo "Rclone Existe ⚡️" || curl https://rclone.org/install.sh | sudo bash

echo "INSTALANDO WO-CLI.."
    if [ -e /usr/local/bin/wo-cli ]; then
	    mv /usr/local/bin/wo-cli /usr/local/bin/wo-cli-old
	    rm -rf /usr/local/bin/wo-cli
	    VAR1=$(sed -n "/^BACKUPS_DIR/p" /usr/local/bin/wo-cli-old)
	    wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
	    sed -i "/BACKUPS_DIR=.*/{ s/BACKUPS_DIR=.*/$VAR1/;:a;n;ba }" /usr/local/bin/wo-cli
	    chmod +x /usr/local/bin/wo-cli
	    rm -rf /usr/local/bin/wo-cli-old
    else
	    wget -O /usr/local/bin/wo-cli https://raw.githubusercontent.com/juanpvh/wo-cli/master/wo-cli.sh
	    chmod +x /usr/local/bin/wo-cli
	fi

rm -rf $HOME/setup.sh
