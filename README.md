# WO-CLI

Script para backup de sites wordpress que utilização WordOps.

### Características principais
---
    Usage: wo-cli (ARGUMENTS...)
	-a <site name> 	: Backup de apenas um site.
	-b              : Backup de todos os sites.
	-c <site name>  : Restaura um site
	-d              : Restaura todos os sites.
	-e              : Configura wo-cli
	-f              : Deletando Backups Antigos
	-g              : Configura o rclone para google-drive # primeira etapa
	-i              : Quantidade de backup(s) por site(s)
	-u              : Update do script.
	-v              : Version
	-h              : Mostra as messagens de help."
---	

### Requerimentos

* [Rclone](https://rclone.org/) - Rclone é um programa de linha de comando para gerenciar arquivos no armazenamento em nuvem.
* [WordOps](https://wordops.net/) - Um conjunto de ferramentas essencial que facilita a administração de sites e servidores WordPress
* [Google-Drive](https://drive.google.com/) - Sistema de compartilhamento e armazenamento de arquivos.

### Novas Features!
  -

### Instalação

Instalando Rclone e WO-CLI.

```sh
$ bash <(curl https://raw.githubusercontent.com/juanpvh/wo-cli/master/setup.sh)
```

### Configuração
Configura o wo-cli
```sh
$ wo-cli -e 
```
Configura o rclone + google drive
```sh
$ wo-cli -g
```

Informações:


| Time | README |
| ------ | ------ |
| crontab | backup realizado sempre as 2:00am|

```sh
$ 0 2 * * * bash /usr/local/bin/wo-cli -b >> /var/log/wo-cli.log 2>&1
```

### Todos

  - Write MORE Tests
  - Add Night Mode

### License

MIT

**Free Software, Hell Yeah!**

