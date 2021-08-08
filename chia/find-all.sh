#!/bin/bash

filename `find /mnt -name "*.plot"` | grep -c plot
filename `find /home/kbalos/net -name "*.plot"` | grep -c plot
