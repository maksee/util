#!/bin/bash

./utils.sh
sensors | grep 'fan[245]\|Core'
./get-nvme.sh
./get-ssd.sh
