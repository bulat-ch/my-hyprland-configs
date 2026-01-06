#!/bin/bash
# ~/.bash_profile

### Original part after Linux/DE/WM install ###

[[ -f ~/.bashrc ]] && . ~/.bashrc

### ###

# Next part will be placed in "/home/<username>/.bash_profile" file

# Make sure that it have execution permissions
# Countdown time in seconds
COUNTDOWN=5

# What are you want to execute
PROGRAM_NAME="Hyprland"
PROGRAM="start-hyprland"

# Interruptable timer
for ((i = COUNTDOWN; i > 0; i--)); do
    echo     "$PROGRAM_NAME will be executed in $i seconds..."
	echo -ne "Press Ctrl+C, if you want to interrupt.\r"
    sleep 1
done

# Executing $PROGRAM
echo ""
echo "Executing $PROGRAM_NAME..."
echo ""
exec "$PROGRAM"
