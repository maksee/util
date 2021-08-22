#!/bin/bash

filename `find /mnt -name "*.plot"` > plots.txt
if [ -e $HOME/net ] && [ `ls -A $HOME/net` ]
then
	filename `find $HOME/net -name "*.plot"` >> plots.txt
fi
cat plots.txt | sort | uniq > plots-uniq.txt
cat plots.txt | sort > plots-sort.txt
diff plots-uniq.txt plots-sort.txt
rm plots.txt plots-sort.txt plots-uniq.txt
