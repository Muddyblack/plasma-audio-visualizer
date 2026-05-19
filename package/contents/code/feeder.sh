#!/usr/bin/env bash
set -eu

BARS="${1:-24}"
FRAMERATE="${2:-60}"
SENSITIVITY="${3:-100}"
NOISE_REDUCTION="${4:-0.77}"

RUN="${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget"
mkdir -p "$RUN"

exec 9>"$RUN/lock"
if ! flock -n 9; then
  exit 0
fi

# Ensure clean termination of background cava process
cleanup() {
  pkill -P $$ || true
}
trap cleanup EXIT

# Generate initial zero-filled string for the requested number of bars
zeros=$(printf '0;%.0s' $(seq 1 "$BARS"))
echo "$zeros" > "$RUN/bars"

# Generate cava.conf dynamically in runtime directory
CONF="$RUN/cava.conf"
cat <<EOF > "$CONF"
[general]
bars = $BARS
framerate = $FRAMERATE
autosens = 1
sensitivity = $SENSITIVITY

[input]
method = pipewire
source = auto

[output]
method = raw
channels = mono
mono_option = average
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = $NOISE_REDUCTION
EOF

cava -p "$CONF" | while IFS= read -r line; do
  printf '%s' "$line" > "$RUN/bars.tmp" && mv -f "$RUN/bars.tmp" "$RUN/bars"
done
