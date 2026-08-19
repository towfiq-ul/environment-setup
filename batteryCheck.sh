#!/bin/bash

HISTORY_DIR="$HOME/.cache/batteryCheck"
HISTORY_FILE="$HISTORY_DIR/history.log"

mkdir -p "$HISTORY_DIR"

OUTPUT=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0)

echo "$OUTPUT"

{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
  echo "$OUTPUT"
  echo
} >> "$HISTORY_FILE"

# keep only the last 1 year of history
CUTOFF=$(date -d '1 year ago' '+%Y-%m-%d')
awk -v cutoff="$CUTOFF" '
  /^===== [0-9]{4}-[0-9]{2}-[0-9]{2} / {
    entry_date = substr($2, 1, 10)
    keep = (entry_date >= cutoff)
  }
  keep { print }
' "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
