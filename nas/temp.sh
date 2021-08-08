#!/bin/bash

dirnm=$(dirname $0)
$dirnm/pkgs.sh
$dirnm/cpu.sh
$dirnm/get-nvme.sh
$dirnm/get-ssd.sh
