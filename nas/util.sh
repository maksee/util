#!/bin/bash

missing_pkgs=""
function check_package() {
        if [ $(dpkg --get-selections | grep -v deinstall | grep -c ^$1) -eq 0 ]
        then
                missing_pkgs="${missing_pkgs} $1"
        fi
}
for i in smbclient cifs-utils lsscsi
do
        check_package $i
done
if [ "${missing_pkgs}" ]
then
        echo "sudo apt-get install${missing_pkgs}"
        exit 1
fi
