#!/bin/bash
#
# Monit EXEC handler that sends monit notifications via Telegram
#
# Depends on having `/usr/local/bin/sendtelegram` installed and a config file in `/etc/telegramrc`
#
/usr/local/bin/sendtelegram -c /etc/telegramrc -m "
$MONIT_HOST
$MONIT_SERVICE
$MONIT_EVENT
$MONIT_DATE
$MONIT_ACTION $MONIT_DESCRIPTION."