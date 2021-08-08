#!/bin/bash

filename `find /mnt -name "*.plot"` > plots.txt
filename `find /home/kbalos/net -name "*.plot"` >> plots.txt
cat plots.txt | sort | uniq > plots-uniq.txt
cat plots.txt | sort > plots-sort.txt
diff plots-uniq.txt plots-sort.txt
rm -v plots.txt plots-sort.txt plots-uniq.txt
