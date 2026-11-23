pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Battery state shared by the bar button and its popup (import qs.services).
Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    // UPower's percentage should be 0..1; also accept 0..100 in case it isn't.
    readonly property int percent: {
        const p = device?.percentage ?? 0;
        return Math.round(p > 1 ? p : p * 100);
    }
    // Plugged in (charging or full).
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
        || device?.state === UPowerDeviceState.FullyCharged
        || device?.state === UPowerDeviceState.PendingCharge
}
