#!/bin/bash

filename `find /mnt -name "*.plot"` | grep -c plot
filename `find $USER/net -name "*.plot"` | grep -c plot
