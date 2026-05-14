import QtQuick 2.15
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: vis

    property int numBars: 24
    property real maxRange: 600.0
    property var bars: Array(numBars).fill(0)
    property bool active: true

    readonly property string feederPath: Qt.resolvedUrl("../code/feeder.sh").toString().replace(/^file:\/\//, "")
    readonly property string barsPath: '"${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget/bars"'

    Plasma5Support.DataSource {
        id: feederLauncher
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) { disconnectSource(source) }
        function spawn() { connectSource("bash " + vis.feederPath) }
        function killFeeder() { connectSource("pkill -f " + vis.feederPath) }
    }

    Plasma5Support.DataSource {
        id: reader
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
            const line = (data["stdout"] || "").trim()
            if (!line) return
            const parts = line.split(";")
            if (parts.length < vis.numBars) return
            const out = []
            for (let i = 0; i < vis.numBars; i++) {
                const v = parseFloat(parts[i])
                out.push(isNaN(v) ? 0 : v)
            }
            vis.bars = out
        }
        function read() { connectSource("cat " + vis.barsPath) }
    }

    Timer {
        interval: 33
        running: vis.active
        repeat: true
        onTriggered: reader.read()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: feederLauncher.spawn()
    }

    Component.onDestruction: feederLauncher.killFeeder()
}
