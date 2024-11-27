#!/bin/sh

# Make sure that it have execution permissions

TOGGLE=$HOME/.config/hypr/scripts/tempfiles/.tempfile_hyprsunset_toggle

if [ ! -e $TOGGLE ]; then
    touch $TOGGLE
    hyprsunset -t 2500
else
    rm $TOGGLE
    killall hyprsunset
fi
