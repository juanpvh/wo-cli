# WO-CLI

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

Script para backup de sites wordpress que utilização WordOps.

### Características principais
---
    Usage: wo-cli (ARGUMENTS...)
	-a <site name> 	: Backup de apenas um site.
	-b              : Backup de todos os sites.
	-c <site name>  : Restaura um site
	-d              : Restaura todos os sites.
    -e              : Configura wo-cli
    -i              : Configura o rclone e wo-cli # primeira etapa
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

```sh
$ wo-cli -g
```

Dillinger is currently extended with the following plugins. Instructions on how to use them in your own application are linked below.

| Time | README |
| ------ | ------ |
| crontab | [plugins/dropbox/README.md][PlDb] |
| GitHub | [plugins/github/README.md][PlGh] |
| Google Drive | [plugins/googledrive/README.md][PlGd] |
| OneDrive | [plugins/onedrive/README.md][PlOd] |
| Medium | [plugins/medium/README.md][PlMe] |
| Google Analytics | [plugins/googleanalytics/README.md][PlGa] |

### Todos

  - Write MORE Tests
  - Add Night Mode

### License

MIT

**Free Software, Hell Yeah!**

