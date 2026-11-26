-- Hyprland config entry point. Each section lives in modules/<name>.lua.
-- See https://wiki.hypr.land/configuring/
-- The original single-file config is kept in hyprland.lua.bak.

require("modules.monitors")
require("modules.env")
require("modules.permissions")
require("modules.look")        -- general, decoration, animations
require("modules.layouts")     -- dwindle / master / scrolling, smart-gaps examples
require("modules.misc")        -- misc, layers
require("modules.input")       -- keyboard, touchpad, gestures, devices
require("modules.keybinds")
require("modules.rules")       -- window / layer rules
require("modules.autostart")
require("modules.quickshell")  -- Quickshell bar autostart

-- hyprmon: managed monitor profile include
require("hyprmon")
