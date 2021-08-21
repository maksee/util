#!/bin/bash

filename `find /mnt -name "*.plot"` | grep -c plot
filename `find $HOME/net -name "*.plot"` | grep -c plot
