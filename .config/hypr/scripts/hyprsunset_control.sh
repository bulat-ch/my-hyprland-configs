#!/bin/sh

TOGGLE_FILE="$HOME/.config/hypr/scripts/tempfiles/.hyprsunset_status"
MODE="$1"

get_status() {
    if [ -f "$TOGGLE_FILE" ]; then
        echo '{"text": "󱁞 ", "tooltip": "Night light: ON (2500K)", "class": "on"}'
    else
        echo '{"text": "󰖔 ", "tooltip": "Night light: OFF", "class": "off"}'
    fi
}

case "$MODE" in
    "toggle")
        if [ -f "$TOGGLE_FILE" ]; then
            rm "$TOGGLE_FILE"
            pkill -x hyprsunset || true
        else
            touch "$TOGGLE_FILE"
            if ! pgrep -x hyprsunset >/dev/null; then
                hyprsunset -t 2500 & disown
            fi
        fi
        for pid in $(pgrep waybar); do
            kill -RTMIN+9 "$pid"
        done
        ;;
    *)
        get_status
        ;;
esac
