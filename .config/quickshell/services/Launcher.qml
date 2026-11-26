pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// App launcher state (window: modules/launcher/LauncherWindow.qml). Opened on the
// focused monitor by `qs ipc call launcher toggle` (SUPER+space in Hyprland).
// Lists the visible .desktop apps, ranked by how well they match the query, then
// by how often they were launched from here. Launch counts are saved to
// ~/.local/state/quickshell/by-shell/<id>/launcher.json (Quickshell.statePath).
Singleton {
    id: root

    property bool open: false
    property string monitor: ""   // Hyprland monitor name the launcher is shown on

    function show() {
        monitor = Hyprland.focusedMonitor?.name ?? "";
        open = true;
    }

    function close() {
        open = false;
    }

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function launch(entry) {
        if (!entry)
            return;
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [Config.terminal, "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
        adapter.uses = Object.assign({}, adapter.uses, { [entry.id]: usesOf(entry) + 1 });
        close();
    }

    function usesOf(entry) {
        return adapter.uses[entry.id] ?? 0;
    }

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // How well `entry` matches the lowercase query `q`, in tiers 100 apart, so a
    // better kind of match always wins and launch counts only order within a tier.
    // 0 = no match.
    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 900;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 800;   // "code" finds "Visual Studio Code"
        if (name.includes(q))
            return 700;
        if ((entry.genericName ?? "").toLowerCase().includes(q))
            return 600;   // "browser" finds Firefox
        if (entry.keywords.some(k => k.toLowerCase().startsWith(q)))
            return 500;
        const bin = (entry.command[0] ?? "").split("/").pop().toLowerCase();
        if (bin.startsWith(q) || entry.id.toLowerCase().includes(q))
            return 400;   // "nvim", "org.kde.dolphin"
        const gaps = subsequenceGaps(name, q);
        if (gaps >= 0)
            return 300 - Math.min(gaps, 99);   // "ffx" finds Firefox
        if ((entry.comment ?? "").toLowerCase().includes(q))
            return 100;
        return 0;
    }

    // Letters of `q` in order inside `s`: the number of skipped characters
    // between them, or -1 if they're not all there.
    function subsequenceGaps(s, q) {
        let gaps = 0;
        let pos = s.indexOf(q[0]);
        if (pos < 0)
            return -1;
        for (let i = 1; i < q.length; i++) {
            const next = s.indexOf(q[i], pos + 1);
            if (next < 0)
                return -1;
            gaps += next - pos - 1;
            pos = next;
        }
        return gaps;
    }

    // Matching apps, best first. An empty query lists every app, most launched first.
    function search(query) {
        const q = query.trim().toLowerCase();
        return apps
            .map(e => ({ entry: e, score: q === "" ? 1 : score(e, q) }))
            .filter(r => r.score > 0)
            .sort((a, b) => (b.score + Math.min(usesOf(b.entry), 99)) - (a.score + Math.min(usesOf(a.entry), 99))
                || a.entry.name.localeCompare(b.entry.name))
            .map(r => r.entry);
    }

    FileView {
        path: Quickshell.statePath("launcher.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property var uses: ({})   // { "<desktop entry id>": launch count }
        }
    }
}
