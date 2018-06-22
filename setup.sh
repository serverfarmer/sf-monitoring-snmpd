#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.install


base=/opt/farm/ext/monitoring-snmpd/templates/$OSVER

if [ ! -f $base/snmpd.tpl ]; then
	echo "skipping snmpd configuration (no template available for $OSVER)"
	exit 1
fi

cfg="/etc/local/.config/snmp.community"

if [ ! -f $cfg ]; then
	if [ "$SNMP_COMMUNITY" = "" ]; then
		echo -n "enter snmp v2 community or hit enter to disable snmpd monitoring: "
		stty -echo
		read SNMP_COMMUNITY
		stty echo
		echo ""  # force a carriage return to be output
	fi
	echo -n "$SNMP_COMMUNITY" >$cfg
	chmod 0600 $cfg
fi

if [ ! -s $cfg ]; then
	echo "skipping snmpd configuration (no community configured)"
	exit 0
fi

/opt/farm/ext/farm-roles/install.sh snmpd

echo "setting up snmpd configuration"
file="/etc/snmp/snmpd.conf"
save_original_config $file

community="`cat $cfg`"
cat $base/snmpd.tpl |sed -e "s/%%community%%/$community/g" -e "s/%%domain%%/`external_domain`/g" -e "s/%%management%%/`management_public_ip_range`/g" >$file

if [ -f $base/snmpd.default ]; then
	remove_link /etc/default/snmpd
	install_copy $base/snmpd.default /etc/default/snmpd
fi

service snmpd restart
echo
