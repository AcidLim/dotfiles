#!/usr/bin/env bash

#不要改这个！！
#修改config.json以应用配置

set -e

CONFIG="$HOME/.config/noctalia/script/matugen/config.json"
LOG="$HOME/.local/state/noctalia/matugen.log"

mkdir -p "$(dirname "$LOG")"

echo "$(date '+%F %T') start" >> "$LOG"


if [ ! -f "$CONFIG" ]; then
    echo "config missing" >> "$LOG"
    exit 1
fi


WALLPAPER=$(noctalia msg wallpaper-get 2>/dev/null)


if [ -z "$WALLPAPER" ]; then
    echo "no wallpaper" >> "$LOG"
    exit 1
fi


if [ ! -f "$WALLPAPER" ]; then
    echo "file missing" >> "$LOG"
    exit 1
fi


TYPE=$(jq -r '.type' "$CONFIG")
MODE=$(jq -r '.mode' "$CONFIG")
PREFER=$(jq -r '.prefer' "$CONFIG")
INDEX=$(jq -r '.source_index' "$CONFIG")
CONTRAST=$(jq -r '.contrast' "$CONFIG")


echo "wallpaper=$WALLPAPER" >> "$LOG"
echo "type=$TYPE mode=$MODE prefer=$PREFER index=$INDEX" >> "$LOG"


matugen image "$WALLPAPER" \
    --type "$TYPE" \
    --mode "$MODE" \
    --prefer "$PREFER" \
    --source-color-index "$INDEX" \
    --contrast "$CONTRAST" \
    >> "$LOG" 2>&1


echo "done" >> "$LOG"
