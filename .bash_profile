#!/bin/bash
# ~/.bash_profile

### Original part after Linux/DE/WM install ###

[[ -f ~/.bashrc ]] && . ~/.bashrc

### ###

# Next part will be placed in "/home/<username>/.bash_profile" file

# Countdown time in seconds
COUNTDOWN=5

# What are you want to execute
PROGRAM="Hyprland"

# Interruptable timer
for ((i = COUNTDOWN; i > 0; i--)); do
    echo     "$PROGRAM will be executed in $i seconds..."
	echo -ne "Press Ctrl+C, if you want to interrupt.\r"
    sleep 1
done

# Executing $PROGRAM
echo ""
echo "Executing $PROGRAM..."
echo ""
exec "$PROGRAM"
