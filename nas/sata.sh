#!/bin/bash

lsscsi -g
dmesg | grep 'SATA link down'

