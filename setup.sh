#!/bin/sh
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.install


base=/opt/farm/ext/monitoring-snmpd/templates/$OSVER

if [ ! -f $base/snmpd.tpl ]; then
	echo "skipping snmpd configuration (no template available for $OSVER)"
	exit 1
fi

file="/etc/local/.config/snmp"

if [ ! -f $file.community ]; then
	if [ "$SNMP_COMMUNITY" = "" ]; then
		echo -n "enter snmp v2 community or hit enter to disable snmpd monitoring: "
		stty -echo
		read SNMP_COMMUNITY
		stty echo
		echo ""  # force a carriage return to be output
	fi
	echo -n "$SNMP_COMMUNITY" >$file.community
	chmod 0600 $file.community
fi

if [ ! -s $file.community ]; then
	echo "skipping snmpd configuration (no community configured)"
	exit 0
fi

/opt/farm/ext/farm-roles/install.sh snmpd

echo "setting up snmpd configuration"
config="/etc/snmp/snmpd.conf"
oldmd5=`md5sum $config`
save_original_config $config

if [ -s $file.range ]; then
	range=`cat $file.range`
else
	range=`/opt/farm/config/get-management-public-ip-range.sh`
fi

community="`cat $file.community`"
domain=`/opt/farm/config/get-external-domain.sh`
cat $base/snmpd.tpl |sed -e "s#%%community%%#$community#g" -e "s#%%domain%%#$domain#g" -e "s#%%management%%#$range#g" >$config
newmd5=`md5sum $config`

if [ -f $base/snmpd.default ]; then
	remove_link /etc/default/snmpd
	install_copy $base/snmpd.default /etc/default/snmpd
fi

if [ "$oldmd5" != "$newmd5" ]; then
	service snmpd restart
	echo
else
	echo "skipping snmpd restart, configuration has not changed"
fi
