#!/bin/sh

TOGGLE_FILE="$HOME/.config/hypr/scripts/tempfiles/.monitor_toggle"
MODE="$1"

get_status() {
    if [ -f "$TOGGLE_FILE" ]; then
        echo '{"text": "󰶐 ", "tooltip": "External monitor: OFF", "class": "off"}'
    else
        echo '{"text": "󱄄 ", "tooltip": "External monitor: ON", "class": "on"}'
    fi
}

case "$MODE" in
    "toggle")
        if [ -f "$TOGGLE_FILE" ]; then
            rm "$TOGGLE_FILE"
            ddcutil -d 1 setvcp d6 1  # Включаем монитор
        else
            touch "$TOGGLE_FILE"
            ddcutil -d 1 setvcp d6 4  # Выключаем монитор
        fi
        pkill -RTMIN+8 waybar
        ;;
    *)
        get_status
        ;;
esac
