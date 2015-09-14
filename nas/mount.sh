#!/bin/bash
#
# (C) Kazimierz Balos
#
# Changed from smbmount to mount -t cifs
#
# Package required: cifs-utils

VERSION=1.0.9
MOUNT_CFG=$HOME/.mount.cfg
ACCESS_TYPE=ro
BASE_DIR=$HOME/net

if [ ! -f ~/.mount.cfg ]
then
	echo "Missing config file: $MOUNT_CFG"
	exit 1
fi 

MOUNT_USER=`cat $MOUNT_CFG | grep user | cut -d= -f2`
MOUNT_PASS=`cat $MOUNT_CFG | grep pass | cut -d= -f2`

function count_volumes() {
	VOL_COUNT=`smbclient -L //$HOST.local -U $MOUNT_USER -N 2>&1 | grep ${PATTERN}.${ACCESS_TYPE} -c`
	echo "${VOL_COUNT}"
}

function print_usage() {
		echo "usage: ./mount.sh hostname {start|stop} [ro|rw]"
}

function remove_dir() {
	if [ -e $1 ]
	then
		rmdir $1
		if [ $? -eq 0 ]
		then
			echo "Directory $1 removed successfully"
		else
			echo "Directory $1 could not be removed"
		fi
	else
		echo "Directory $1 does not exist"
	fi
}

function create_dir() {
	if [ ! -e $1 ]
	then
		mkdir -p $1
		if [ $? -eq 0 ]
		then
			echo "Directory $1 created successfully"
		else
			echo "Directory $1 could not be created"
		fi
		else
		echo "Directory $1 already exists" 
	fi
}

if [ $# -eq 2 -o $# -eq 3 ]
then
	echo "$0 version $VERSION"
	HOST=$1
	PATTERN=fa
	if [ $HOST == "nas" ]
	then
		PATTERN=vol
	fi
else 
	print_usage
	exit 0
fi

if [ $# -eq 3 ]
then
	ACCESS_TYPE=$3
fi

case $2 in 
home-start)
	sudo mount -t cifs //$HOST.local/$MOUNT_USER $BASE_DIR/$HOST/$MOUNT_USER -ousername=$MOUNT_USER,password=$MOUNT_PASS
;;
home-stop)
	sudo umount $BASE_DIR/$HOST/$MOUNT_USER
;;
start)
	VOL_COUNT=$(count_volumes)
	echo "Number of volumes detected: ${VOL_COUNT}"
	for i in `seq 1 $VOL_COUNT`
	do
		DIR=${PATTERN}${i}
		DIR_FULL=$BASE_DIR/${HOST}/${DIR}
		create_dir ${DIR_FULL}
		sudo mount -t cifs //$HOST.local/${DIR}${ACCESS_TYPE} ${DIR_FULL} -ousername=$MOUNT_USER,password=$MOUNT_PASS
	done
;;
stop)
	VOL_COUNT=$(count_volumes)
	echo "Number of volumes detected: ${VOL_COUNT}"
	for i in `seq 1 $VOL_COUNT`
	do
		DIR=${PATTERN}${i}
		DIR_FULL=$BASE_DIR/${HOST}/${DIR}
		if [ -e ${DIR_FULL} ]
		then 
			sudo umount ${DIR_FULL}
			echo "Directory ${DIR_FULL} unmounted successfully"
		fi
		remove_dir ${DIR_FULL}
	done
	remove_dir $BASE_DIR/$HOST
;;
*)
	print_usage
	exit 0
;;
esac
df -h | grep $PATTERN
