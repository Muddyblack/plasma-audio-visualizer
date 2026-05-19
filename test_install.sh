#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/plasma-audio-visualizer-test"

# Clean up any existing temp dir
rm -rf "$TEMP_DIR"
cp -r "$HERE/package" "$TEMP_DIR"

# Modify metadata.json to change ID and Name to avoid collision
sed -i 's/"Id": "org.muddyblack.plasmaAudioVisualizer"/"Id": "org.muddyblack.plasmaAudioVisualizerTest"/g' "$TEMP_DIR/metadata.json"
sed -i 's/"Name": "Plasma Audio Visualizer"/"Name": "Plasma Audio Visualizer (Test)"/g' "$TEMP_DIR/metadata.json"

echo "Installing test version of the widget..."
if kpackagetool6 -t Plasma/Applet -l | grep -q "org.muddyblack.plasmaAudioVisualizerTest"; then
    kpackagetool6 -t Plasma/Applet -u "$TEMP_DIR"
else
    kpackagetool6 -t Plasma/Applet -i "$TEMP_DIR"
fi

echo ""
echo "=== Test Widget Installed! ==="
echo "You can now add 'Plasma Audio Visualizer (Test)' to your panel to test the customization features."
echo "To uninstall the test version later, run:"
echo "  kpackagetool6 -t Plasma/Applet -r org.muddyblack.plasmaAudioVisualizerTest"
