#!/usr/bin/env bash

# -------------------------------
# Simple AUR uptime checker
# Sends KDE notification on status change
# -------------------------------

URL="https://aur.archlinux.org/"
STATE_FILE="${HOME}/.cache/check_aur_state"
mkdir -p "$(dirname "$STATE_FILE")"

# Get last known state
if [[ -f "$STATE_FILE" ]]; then
  PREV_STATE=$(cat "$STATE_FILE")
else
  PREV_STATE="unknown"
fi

# Check HTTP status
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$URL")

if [[ "$HTTP_CODE" == "200" ]]; then
  CURRENT_STATE="up"
else
  CURRENT_STATE="down"
fi

# Save current state
echo "$CURRENT_STATE" > "$STATE_FILE"

# Notify if state changed
if [[ "$CURRENT_STATE" != "$PREV_STATE" ]]; then
  if [[ "$CURRENT_STATE" == "up" ]]; then
    kdialog --passivepopup "✅ AUR is back up! ($HTTP_CODE)" 5
  else
    kdialog --passivepopup "❌ AUR appears down. (HTTP $HTTP_CODE)" 5
  fi
fi
