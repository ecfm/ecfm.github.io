#!/bin/sh
# One-time pickup from my personal Claude status box.
# Usage:  curl -sL ecfm.github.io/b|sh -s CODE
# CODE is a six-letter pickup code that works once, for 30 minutes. This file holds no secret.
# It fetches a short text from the box, saves its first line as the read-side config
# (~/.config/claude-status/pull.json, mode 600) and the rest as report.txt beside it.
u='https://script.google.com/macros/s/AKfycbySX5Ou0hM0mzb_mzqUZBWb0RgLzpOnOzWdlt_y-cCUkjQilZJppqw78OlbUqwJqnSC/exec'
d="$HOME/.config/claude-status"
[ -n "$1" ] || { echo "usage: curl -sL ecfm.github.io/b|sh -s CODE"; exit 1; }
umask 077
mkdir -p "$d"
t="$d/pickup.tmp"
curl -sL "$u?pickup=$1" > "$t"
if head -1 "$t" | grep -q '^{"url"'; then
  head -1 "$t" > "$d/pull.json"
  tail -n +2 "$t" > "$d/report.txt"
  rm -f "$t"
  echo "ok: saved $d/pull.json, report in $d/report.txt"
else
  echo "pickup failed (wrong, used or expired code): $(head -c 60 "$t")"
  rm -f "$t"
  exit 1
fi
