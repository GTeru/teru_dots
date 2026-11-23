import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// Full-screen wallpaper for one monitor, on the background layer (below all windows).
// Instantiated once per screen by shell.qml. Not named Wallpaper, which is the
// service singleton.
//
// Crossfade: two Images take turns. A new wallpaper loads into the hidden one;
// once it's ready, it's raised above the current one and faded in.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    color: Theme.bg

    // Image currently on top (fully shown once its fade finishes).
    property Image front: imageA

    function load(path) {
        if (path === "") {
            // No images: show the gradient.
            imageA.opacity = 0;
            imageB.opacity = 0;
            return;
        }
        const back = front === imageA ? imageB : imageA;
        const url = `file://${path}`;
        if (back.source.toString() === url && back.status === Image.Ready)
            show(back);
        else
            back.source = url;   // shown from onStatusChanged once loaded
    }

    function show(image) {
        if (image === front && image.opacity === 1)
            return;
        front.z = 0;
        image.z = 1;
        front = image;
        fade.target = image;
        fade.restart();
    }

    Component.onCompleted: load(Wallpaper.current)

    Connections {
        target: Wallpaper
        function onCurrentChanged() { root.load(Wallpaper.current); }
    }

    NumberAnimation {
        id: fade
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.wallpaperFadeDuration
        easing.type: Easing.InOutQuad
    }

    // Placeholder under the images: shown while there are none, or one fails to load.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bg }
            GradientStop { position: 0.65; color: "#24283b" }
            GradientStop { position: 1.0; color: Theme.accentDim }
        }
    }

    component WallpaperImage: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: 0
        onStatusChanged: {
            if (status === Image.Ready && source.toString() === `file://${Wallpaper.current}`)
                root.show(this);
            else if (status === Image.Error)
                console.warn(`wallpaper: can't load ${source}`);
        }
    }

    WallpaperImage { id: imageA }
    WallpaperImage { id: imageB }
}
