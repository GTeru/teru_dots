pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// Bar-only workspace names, renamed at runtime. Saved in $XDG_RUNTIME_DIR (tmpfs),
// so they survive `qs` restarts but are cleared on reboot or full logout.
// Hyprland still knows workspaces by number. Without a custom name, an occupied
// workspace is labelled with the app of its last-focused window (see appOf).
Singleton {
    id: root

    // Workspace currently being renamed in the bar, or -1.
    property int editingId: -1

    // Last-focused window per workspace: { "<workspace id>": "<toplevel address>" }.
    // Not saved; after a restart it falls back to the first window until one is focused.
    property var lastFocused: ({})

    // Rename the focused workspace (bound to a Hyprland key via `qs ipc call workspaces rename`).
    function startRename() {
        editingId = Hyprland.focusedWorkspace?.id ?? -1;
    }

    function cancelRename() {
        editingId = -1;
    }

    // Empty/whitespace name clears it.
    function setName(id, name) {
        const names = Object.assign({}, adapter.names);
        const trimmed = name.trim();
        if (trimmed)
            names[id] = trimmed;
        else
            delete names[id];
        adapter.names = names;
        editingId = -1;
    }

    function nameOf(id) {
        return adapter.names[id] ?? "";
    }

    // Short app name for a workspace's last-focused window (else its first one),
    // from the Wayland app id: "com.mitchellh.ghostty" → "ghostty". "" when empty.
    function appOf(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        const windows = ws?.toplevels?.values ?? [];
        if (windows.length === 0)
            return "";
        const win = windows.find(t => t.address === lastFocused[id]) ?? windows[0];
        const appId = win.wayland?.appId || win.lastIpcObject?.class || "";
        const short = appId.split(".").pop().toLowerCase();
        return short.length > Config.workspaceAppNameMax ? short.slice(0, Config.workspaceAppNameMax - 1) + "…" : short;
    }

    // Occupied: "1-web" with a custom name, else "1-ghostty" from its app. Empty: "1".
    function label(id, occupied) {
        if (!occupied)
            return String(id);
        const name = nameOf(id) || appOf(id);
        return name ? `${id}-${name}` : String(id);
    }

    // Remember which window was focused last on each workspace.
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            const t = Hyprland.activeToplevel;
            const ws = t?.workspace?.id;
            if (ws === undefined || root.lastFocused[ws] === t.address)
                return;
            root.lastFocused = Object.assign({}, root.lastFocused, { [ws]: t.address });
        }
    }

    // Stop editing if focus moves to another workspace mid-rename.
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (root.editingId !== -1 && Hyprland.focusedWorkspace?.id !== root.editingId)
                root.cancelRename();
        }
    }

    FileView {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-workspace-names.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property var names: ({})   // { "<workspace id>": "<name>" }
        }
    }
}
