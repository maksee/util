#!/bin/bash

sensors | grep 'fan[1-5]\|Core' | sed 's/(min =.*0 RPM)//'
