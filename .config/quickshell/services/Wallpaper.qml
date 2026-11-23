pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

// The wallpaper drawn by modules/wallpaper/WallpaperWindow.qml on every monitor.
// Images come from wallpapers/ in this config (jpg, png, webp), sorted by name.
// The choice is saved in Quickshell.statePath("wallpaper.json"). With no images,
// the windows draw a Tokyo Night gradient instead.
//
// From outside: `qs ipc call wallpaper next|prev|set <file>|get` (see shell.qml).
Singleton {
    id: root

    readonly property string folder: Quickshell.shellDir + "/wallpapers"

    // Absolute paths of the images in `folder`.
    readonly property var images: {
        const list = [];
        for (let i = 0; i < files.count; i++)
            list.push(files.get(i, "filePath"));
        return list;
    }

    // Path to show: the saved choice, or the first image. "" means the gradient.
    readonly property string current: adapter.path !== "" ? adapter.path : (images[0] ?? "")

    // A file name in `folder` ("forest.jpg") or an absolute path. "" resets to the first image.
    function set(path) {
        adapter.path = path === "" || path.startsWith("/") ? path : `${folder}/${path}`;
    }

    function step(delta) {
        if (images.length === 0)
            return;
        const i = images.indexOf(current);
        // Not in the folder (e.g. set by absolute path): start from the first image.
        const next = i === -1 ? 0 : (i + delta + images.length) % images.length;
        adapter.path = images[next];
    }

    function next() { step(1); }
    function prev() { step(-1); }

    FolderListModel {
        id: files
        folder: `file://${root.folder}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
        caseSensitive: false
        sortField: FolderListModel.Name
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string path: ""   // "" = first image in the folder
        }
    }
}
