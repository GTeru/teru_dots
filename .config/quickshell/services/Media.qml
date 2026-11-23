pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The media player the bar shows (import qs.services → Media.player).
Singleton {
    readonly property var players: Mpris.players.values
    // Prefer a player that's playing, otherwise the first one (e.g. paused).
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
}
