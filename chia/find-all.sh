#!/bin/bash

filename `find /mnt -name "*.plot"` | grep -c plot
if [ -e $HOME/net ] && [ `ls -A $HOME/net` ]
then
	filename `find $HOME/net -name "*.plot"` | grep -c plot
fi
