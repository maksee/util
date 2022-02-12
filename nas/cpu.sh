#!/bin/bash

sensors | grep 'fan[1-5]\|Core' | sed -e 's/(min =.*0 RPM)//' -e '/  0 RPM/d'
