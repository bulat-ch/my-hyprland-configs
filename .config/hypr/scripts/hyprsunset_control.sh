#!/bin/sh

TOGGLE_FILE="$HOME/.config/hypr/scripts/tempfiles/.hyprsunset_toggle"
MODE="$1"

get_status() {
    if [ -f "$TOGGLE_FILE" ]; then
        echo '{"text": " "}'
    else
        echo '{"text": " "}'
    fi
}

case "$MODE" in
    "toggle")
        if [ -f "$TOGGLE_FILE" ]; then
            rm "$TOGGLE_FILE"
            hyprsunset -t 2500    # enable hyprsunset
        else
            touch "$TOGGLE_FILE"
            killall hyprsunset    # disable hyprsunset
        fi
       pkill -RTMIN+9 waybar
        ;;
    *)
        get_status
        ;;
esac
