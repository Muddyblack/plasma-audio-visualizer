import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Layout.minimumWidth: 340
    Layout.minimumHeight: 64
    Layout.preferredWidth: 300
    Layout.preferredHeight: 84

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: "NoBackground"

    readonly property string artist: mpris2Model.currentPlayer?.artist ?? ""
    readonly property string track: mpris2Model.currentPlayer?.track ?? ""
    readonly property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0
    readonly property bool isPlaying: playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool hasPlayer: !!mpris2Model.currentPlayer
    readonly property color accentColor: Kirigami.Theme.highlightColor
    readonly property color textColor: Kirigami.Theme.textColor

    property string artUrl: ""
    readonly property string _rawArtUrl: mpris2Model.currentPlayer?.artUrl ?? ""
    on_RawArtUrlChanged: if (_rawArtUrl !== "") artUrl = _rawArtUrl

    // Cava always runs — wave reacts to whatever's playing system-wide,
    // independent of whether MPRIS players are reporting state correctly.
    Visualizer { id: vis; numBars: 24; active: true }

    fullRepresentation: RowLayout {
        spacing: 12

        // ── Album art and controls ────────────────────────────────────────
        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Item {
                id: artBox
                Layout.preferredWidth: Math.min(parent.height - 12, 60)
                Layout.preferredHeight: Math.min(parent.height - 12, 60)
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "audio-x-generic-symbolic"
                    width: parent.width * 0.45
                    height: width
                    opacity: 0.35
                }

                Image {
                    id: artImg
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }

                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: 10
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: artImg
                    maskEnabled: true
                    maskSource: artMask
                    opacity: (artImg.status === Image.Ready || artImg.status === Image.Loading) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                }
            }

            // ── Glassy transport dock ─────────────────────────────────────
            Item {
                id: controlDock
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 82
                Layout.preferredHeight: 24
                visible: root.hasPlayer

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    border.color: Qt.rgba(1, 1, 1, 0.24)
                    border.width: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                        GradientStop { position: 0.45; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.03, 0.07, 0.36) }
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.accentColor
                        shadowOpacity: root.isPlaying ? 0.22 : 0.12
                        shadowBlur: 0.34
                        shadowVerticalOffset: 1
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 2
                        height: 1
                        radius: 1
                        color: Qt.rgba(1, 1, 1, 0.38)
                    }
                }

                RowLayout {
                    id: controlRow
                    anchors.centerIn: parent
                    spacing: 2

                    // Previous Button
                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        scale: prevArea.pressed ? 0.94 : (prevArea.containsMouse ? 1.07 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            source: "media-skip-backward"
                            color: "white"
                            opacity: prevArea.containsMouse ? 1.0 : 0.78
                        }
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            anchors.margins: -2
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = mpris2Model.currentPlayer
                                if (!p) return
                                if (p.previous) p.previous()
                                else if (p.Previous) p.Previous()
                            }
                        }
                    }

                    // Play/Pause Button
                    Item {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 22
                        scale: playArea.pressed ? 0.94 : (playArea.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            source: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                            color: "white"
                            opacity: playArea.containsMouse ? 1.0 : 0.86
                        }
                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            anchors.margins: -2
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = mpris2Model.currentPlayer
                                if (!p) return
                                if (p.playPause) p.playPause()
                                else if (p.PlayPause) p.PlayPause()
                                else if (root.isPlaying) (p.pause || p.Pause || function(){})()
                                else (p.play || p.Play || function(){})()
                            }
                        }
                    }

                    // Next Button
                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        scale: nextArea.pressed ? 0.94 : (nextArea.containsMouse ? 1.07 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            source: "media-skip-forward"
                            color: "white"
                            opacity: nextArea.containsMouse ? 1.0 : 0.78
                        }
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            anchors.margins: -2
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = mpris2Model.currentPlayer
                                if (!p) return
                                if (p.next) p.next()
                                else if (p.Next) p.Next()
                            }
                        }
                    }
                }
            }
        }

        // ── Waveform + text ───────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Canvas {
                id: wave
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.5
                antialiasing: true
                renderStrategy: Canvas.Cooperative

                Connections {
                    target: vis
                    function onBarsChanged() { wave.requestPaint() }
                }
                Connections {
                    target: root
                    function onIsPlayingChanged() { wave.requestPaint() }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    const mid = height / 2
                    const n = vis.numBars
                    const step = width / (n - 1)

                    if (!root.isPlaying) {
                        ctx.lineWidth = 1.2
                        ctx.strokeStyle = Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.35)
                        ctx.beginPath()
                        ctx.moveTo(2, mid)
                        ctx.lineTo(width - 2, mid)
                        ctx.stroke()
                        return
                    }

                    ctx.lineWidth = 1.8
                    ctx.strokeStyle = root.accentColor

                    function plot(sign) {
                        ctx.beginPath()
                        const amp = height * 0.42
                        let prevX = 0
                        let prevY = mid + sign * ((vis.bars[0] || 0) / vis.maxRange) * amp
                        ctx.moveTo(prevX, prevY)
                        for (let i = 1; i < n; i++) {
                            const v = (vis.bars[i] || 0) / vis.maxRange
                            const x = i * step
                            const y = mid + sign * v * amp
                            const cpX = (prevX + x) / 2
                            ctx.bezierCurveTo(cpX, prevY, cpX, y, x, y)
                            prevX = x
                            prevY = y
                        }
                        ctx.stroke()
                    }

                    plot(-1)
                    plot(1)
                }
            }

            // ── Seekable progress pulse ──────────────────────────────────
            Item {
                id: progressBar
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.topMargin: 1
                Layout.bottomMargin: 1
                
                // Visible only if we have a player and a valid track length
                visible: root.hasPlayer && lengthValue > 0
                opacity: visible ? 1.0 : 0.0

                property real lengthValue: playerLength()
                property real displayedPosition: 0
                property real anchorPosition: 0
                property real anchorMs: Date.now()
                property real progress: lengthValue > 0 ? clamp(displayedPosition / lengthValue, 0, 1) : 0
                property real sweep: -0.35
                readonly property string elapsedText: formatTime(displayedPosition)
                readonly property string totalText: formatTime(lengthValue)

                function clamp(value, min, max) {
                    return Math.max(min, Math.min(max, value))
                }

                function playerLength() {
                    const p = mpris2Model.currentPlayer
                    if (!p) return 0
                    return Math.max(0, p.length || p.mprisLength || 0)
                }

                function playerPosition() {
                    const p = mpris2Model.currentPlayer
                    if (!p) return 0
                    return clamp(p.position || 0, 0, lengthValue)
                }

                function unitsPerSecond() {
                    if (lengthValue >= 1000000) return 1000000
                    if (lengthValue >= 10000) return 1000
                    return 1
                }

                function predictedPosition() {
                    if (!root.isPlaying) return anchorPosition
                    const elapsedMs = Date.now() - anchorMs
                    return clamp(anchorPosition + elapsedMs * unitsPerSecond() / 1000, 0, lengthValue)
                }

                function syncFromPlayer(hard) {
                    const len = playerLength()
                    lengthValue = len

                    if (len <= 0) {
                        displayedPosition = 0
                        anchorPosition = 0
                        anchorMs = Date.now()
                        return
                    }

                    const rawPosition = playerPosition()
                    const predicted = predictedPosition()
                    const drift = Math.abs(rawPosition - predicted)
                    const seekSizedDrift = drift > unitsPerSecond() * 1.25

                    anchorPosition = rawPosition
                    anchorMs = Date.now()

                    if (hard || seekSizedDrift || !root.isPlaying || displayedPosition <= 0) {
                        displayedPosition = rawPosition
                    }
                }

                function tick() {
                    const len = playerLength()
                    if (len !== lengthValue) lengthValue = len
                    if (lengthValue <= 0) return
                    displayedPosition = predictedPosition()
                }

                function twoDigits(value) {
                    return value < 10 ? "0" + value : "" + value
                }

                function formatTime(value) {
                    const seconds = Math.max(0, Math.floor(value / unitsPerSecond()))
                    const hours = Math.floor(seconds / 3600)
                    const minutes = Math.floor((seconds % 3600) / 60)
                    const secs = seconds % 60
                    if (hours > 0) {
                        return hours + ":" + twoDigits(minutes) + ":" + twoDigits(secs)
                    }
                    return minutes + ":" + twoDigits(secs)
                }

                Behavior on opacity { NumberAnimation { duration: 180 } }

                Component.onCompleted: syncFromPlayer(true)

                Connections {
                    target: root
                    function onIsPlayingChanged() { progressBar.syncFromPlayer(true) }
                    function onTrackChanged() { progressBar.syncFromPlayer(true) }
                    function onHasPlayerChanged() { progressBar.syncFromPlayer(true) }
                }

                Connections {
                    target: mpris2Model.currentPlayer
                    ignoreUnknownSignals: true
                    function onPositionChanged() { progressBar.syncFromPlayer(false) }
                    function onLengthChanged() { progressBar.syncFromPlayer(true) }
                    function onMprisLengthChanged() { progressBar.syncFromPlayer(true) }
                }

                Timer {
                    interval: 50
                    running: root.hasPlayer
                    repeat: true
                    onTriggered: progressBar.tick()
                }

                SequentialAnimation on sweep {
                    running: root.isPlaying && progressBar.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: -0.35; to: 1.35; duration: 1450; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: 280 }
                }

                Rectangle {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    height: pbArea.containsMouse ? 5 : 3
                    radius: height / 2
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: 1
                    
                    Behavior on height { NumberAnimation { duration: 150 } }

                    Item {
                        id: progressFillClip
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * progressBar.progress
                        clip: true
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.Linear } }

                        Rectangle {
                            anchors.fill: parent
                            radius: progressTrack.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.62) }
                                GradientStop { position: 0.65; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.95) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.82) }
                            }
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: root.accentColor
                                shadowOpacity: root.isPlaying ? 0.38 : 0.18
                                shadowBlur: 0.28
                            }
                        }

                        Rectangle {
                            width: Math.max(18, progressTrack.width * 0.22)
                            height: parent.height
                            radius: parent.height / 2
                            x: (progressFillClip.width + width) * progressBar.sweep - width
                            opacity: root.isPlaying ? 0.72 : 0.0
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.78) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                            }
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                    }

                    Rectangle {
                        width: pbArea.containsMouse ? 8 : 6
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * progressBar.progress - width / 2))
                        color: Qt.rgba(1, 1, 1, root.isPlaying ? 0.95 : 0.68)
                        opacity: progressBar.progress > 0 ? 1.0 : 0.0
                        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.Linear } }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.accentColor
                            shadowOpacity: root.isPlaying ? 0.55 : 0.22
                            shadowBlur: 0.40
                        }

                        SequentialAnimation on scale {
                            running: root.isPlaying && progressBar.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.92; to: 1.18; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.18; to: 0.92; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: progressBar.elapsedText
                    color: root.textColor
                    opacity: 0.50
                    font.pixelSize: 8
                }

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: progressBar.totalText
                    color: root.textColor
                    opacity: 0.50
                    font.pixelSize: 8
                }

                MouseArea {
                    id: pbArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: (mouse) => {
                        const p = mpris2Model.currentPlayer
                        if (!p) return
                        const len = p.length || p.mprisLength || 0
                        if (!len) return
                        
                        const ratio = progressTrack.width > 0 ? progressBar.clamp((mouse.x - progressTrack.x) / progressTrack.width, 0, 1) : 0
                        const newPos = ratio * len
                        progressBar.displayedPosition = newPos
                        progressBar.anchorPosition = newPos
                        progressBar.anchorMs = Date.now()
                        
                        // Robust seek implementation for different MPRIS layers
                        if (typeof p.position !== "undefined" && p.canSeek !== false) {
                            p.position = newPos
                        } else if (typeof p.SetPosition === "function") {
                            p.SetPosition(newPos)
                        } else if (typeof p.setPosition === "function") {
                            p.setPosition(newPos)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.track
                color: root.textColor
                font.bold: true
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: root.textColor
                opacity: 0.6
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    Mpris.Mpris2Model { id: mpris2Model }
}
