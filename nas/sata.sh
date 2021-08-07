#!/bin/bash

lsscsi -g
dmesg | grep 'SATA link up'
dmesg | grep 'SATA link down'

