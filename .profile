#!/bin/bash
# Make sure it has execute permissions on your system!

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
