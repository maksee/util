#!/bin/bash
#
# (C) Kazimierz Balos
#
# Changed from smbmount to mount -t cifs
#
# Package required: smbclient cifs-utils

VERSION=1.0.10
MOUNT_CFG=$HOME/.mount.cfg
ACCESS_TYPE=ro
BASE_DIR=$HOME/net
# vol0, vol1, ...
START_IDX=0

if [ ! -f ~/.mount.cfg ]
then
	echo "Missing config file: $MOUNT_CFG"
	exit 1
fi 

MOUNT_USER=`cat $MOUNT_CFG | grep username | cut -d= -f2`
MOUNT_PASS=`cat $MOUNT_CFG | grep password | cut -d= -f2`

function count_volumes() {
	VOL_COUNT=`smbclient -L //$HOST.local -U $MOUNT_USER -A $MOUNT_CFG 2>&1 | grep ${PATTERN}.${ACCESS_TYPE} -c`
	echo "${VOL_COUNT}"
}

function print_usage() {
		echo "usage: ./mount.sh hostname {start|stop|status} [ro|rw]"
}

function remove_dir() {
	if [ -e $1 ]
	then
		rmdir $1
		if [ $? -eq 0 ]
		then
			echo " removed"
		else
			echo " could not be removed"
		fi
	else
		echo " does not exist"
	fi
}

function create_dir() {
	if [ ! -e $1 ]
	then
		mkdir -p $1
		if [ $? -eq 0 ]
		then
			echo "Directory $1 created successfully"
			echo -n ""
		else
			echo "Directory $1 could not be created"
		fi
		else
		echo "Directory $1 already exists" 
	fi
}

if [ $# -eq 1 ]
then
	if [ $1 = "status" ]
	then
		PATTERN=vol
		df -h | grep $PATTERN
		exit 0
	fi
fi

if [ $# -eq 2 -o $# -eq 3 ]
then
	echo "$0 version $VERSION"
	HOST=$1
	PATTERN=vol
	echo "HOST=$HOST PATTERN=$PATTERN"
else 
	print_usage
	exit 0
fi

if [ $# -eq 3 ]
then
	ACCESS_TYPE=$3
fi

case $2 in 
start)
	VOL_COUNT=`expr $(count_volumes) - 1`
	echo "Number of volumes detected: ${VOL_COUNT}"
	for i in `seq $START_IDX $VOL_COUNT`
	do
		DIR=${PATTERN}${i}
		DIR_FULL=$BASE_DIR/${HOST}/${DIR}
		create_dir ${DIR_FULL}
		#echo "sudo mount -t cifs //$HOST.local/${DIR}${ACCESS_TYPE} ${DIR_FULL} -ousername=$MOUNT_USER,password=$MOUNT_PASS"
		sudo mount -t cifs //$HOST.local/${DIR}${ACCESS_TYPE} ${DIR_FULL} -ousername=$MOUNT_USER,password=$MOUNT_PASS
	done
;;
stop)
	VOL_COUNT=`expr $(count_volumes) - 1`
	echo "Number of volumes detected: ${VOL_COUNT}"
	for i in `seq $START_IDX $VOL_COUNT`
	do
		DIR=${PATTERN}${i}
		DIR_FULL=$BASE_DIR/${HOST}/${DIR}
		echo -n "Directory ${DIR_FULL}:"
		if [ -e ${DIR_FULL} ]
		then 
			sudo umount ${DIR_FULL}
			echo -n " unmounted"
                else
			echo -n " could not be unmounted"
		fi
		remove_dir ${DIR_FULL}
	done
	echo -n "Directory ${BASE_DIR}/${HOST}:"
	remove_dir $BASE_DIR/$HOST
	echo -n "Directory ${BASE_DIR}:"
	remove_dir $BASE_DIR
;;
*)
	print_usage
	exit 0
;;
esac
df -h | grep $PATTERN
