#!/bin/bash

if [ -e /usr/bin/dpkg ]
then
	: # proceeding
else
	exit 0
fi
missing_pkgs=""
function check_package() {
        if [ $(dpkg --get-selections | grep -v deinstall | grep -c ^$1) -eq 0 ]
        then
                missing_pkgs="${missing_pkgs} $1"
        fi
}
# ncdu is useful to spot sparse file - it shows actual space occupied by a file
for i in smbclient cifs-utils lsscsi smartmontools hddtemp lm-sensors nvme-cli wcstools ethtool ncdu
do
        check_package $i
done
if [ "${missing_pkgs}" ]
then
        echo "sudo apt-get install${missing_pkgs}"
        exit 1
fi
