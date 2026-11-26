pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs.config

// Desktop notification server (org.freedesktop.Notifications), replacing dunst.
// Every notification is kept (`tracked`) until dismissed: that's the history in
// the bar's notification popup. New ones also show as a toast
// (modules/notifications/NotificationToasts.qml) for Config.notificationTimeout,
// unless do-not-disturb is on. Critical ones always toast and stay until closed.
//
// Toast state lives here, not in the toast windows, so every monitor's window
// agrees on it. `toasts` maps notification id → expiry time (ms, 0 = sticky).
Singleton {
    id: root

    readonly property var list: server.trackedNotifications   // ObjectModel of Notification
    readonly property int count: server.trackedNotifications.values.length
    readonly property bool dnd: adapter.dnd

    property var toasts: ({})
    // Arrival time per id, for "5m ago". Unknown for ones kept over a reload.
    property var arrived: ({})
    // Set by the toast windows; a hovered toast doesn't expire.
    property bool toastsHovered: false
    // Ticks every 30 s so relative times update.
    property real now: Date.now()

    function setDnd(on) { adapter.dnd = on; }
    function toggleDnd() { adapter.dnd = !adapter.dnd; }

    function isToast(id) { return toasts[id] !== undefined; }

    function find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function dropToast(id) {
        if (!isToast(id))
            return;
        const t = Object.assign({}, toasts);
        delete t[id];
        toasts = t;
        // Transient notifications don't belong in the history.
        const n = find(id);
        if (n && n["transient"])
            n.expire();
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        toasts = {};
        arrived = {};
    }

    function ago(id) {
        const t = arrived[id];
        if (t === undefined)
            return "";
        const m = Math.floor((now - t) / 60000);
        if (m < 1) return "now";
        if (m < 60) return `${m}m`;
        const h = Math.floor(m / 60);
        return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            const id = n.id;
            root.arrived = Object.assign({}, root.arrived, { [id]: Date.now() });
            n.closed.connect(() => root.dropToast(id));

            const critical = n.urgency === NotificationUrgency.Critical;
            if (root.dnd && !critical)
                return;
            // expireTimeout is in seconds; <= 0 means "server default".
            const ms = n.expireTimeout > 0 ? Math.max(2000, n.expireTimeout * 1000) : Config.notificationTimeout;
            const t = Object.assign({}, root.toasts, { [id]: critical ? 0 : Date.now() + ms });
            // Too many on screen: drop the oldest non-critical ones.
            const ids = Object.keys(t).map(Number).sort((a, b) => a - b);
            for (let i = 0; ids.length - i > Config.notificationMaxToasts && i < ids.length; i++)
                if (t[ids[i]] !== 0)
                    delete t[ids[i]];
            root.toasts = t;
        }
    }

    // Expire toasts. Paused while hovered; leaving gives each at least 2 s more.
    Timer {
        interval: 250
        repeat: true
        running: Object.keys(root.toasts).length > 0 && !root.toastsHovered
        onTriggered: {
            const now = Date.now();
            for (const [id, at] of Object.entries(root.toasts))
                if (at !== 0 && at <= now)
                    root.dropToast(Number(id));
        }
    }
    onToastsHoveredChanged: {
        if (toastsHovered)
            return;
        const min = Date.now() + 2000;
        const t = {};
        for (const [id, at] of Object.entries(toasts))
            t[id] = at === 0 ? 0 : Math.max(at, min);
        toasts = t;
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.count > 0
        onTriggered: root.now = Date.now()
    }

    FileView {
        path: Quickshell.statePath("notifications.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool dnd: false
        }
    }
}
