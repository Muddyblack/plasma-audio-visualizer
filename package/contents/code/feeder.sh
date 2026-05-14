#!/usr/bin/env bash
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HERE/cava.conf"

RUN="${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget"
mkdir -p "$RUN"

exec 9>"$RUN/lock"
if ! flock -n 9; then
  exit 0
fi

echo "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0" > "$RUN/bars"

cava -p "$CONF" | while IFS= read -r line; do
  printf '%s' "$line" > "$RUN/bars.tmp" && mv -f "$RUN/bars.tmp" "$RUN/bars"
done
