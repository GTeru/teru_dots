pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Bar-only workspace names, renamed at runtime and saved across restarts in
// ~/.local/state/quickshell/by-shell/<id>/workspace-names.json (Quickshell.statePath).
// Hyprland still knows workspaces by number.
Singleton {
    id: root

    // Workspace currently being renamed in the bar, or -1.
    property int editingId: -1

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

    // "1-web" when the workspace has windows and a name, otherwise just "1".
    function label(id, occupied) {
        const name = nameOf(id);
        return occupied && name ? `${id}-${name}` : String(id);
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
        path: Quickshell.statePath("workspace-names.json")
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
