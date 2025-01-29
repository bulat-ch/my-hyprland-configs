#!/bin/sh

# Make sure that it have execution permissions

TOGGLE=$HOME/.config/hypr/scripts/tempfiles/.tempfile_monitor_toggle

if [ ! -e $TOGGLE ]; then
    touch $TOGGLE
    ddcutil -d 1 setvcp d6 4
else
    rm $TOGGLE
    ddcutil -d 1 setvcp d6 1
fi
