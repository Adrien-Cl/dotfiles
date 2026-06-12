-- Hyprland configuration — Lua format (0.55+)

-- Variables (globales pour être accessibles dans les modules dofile)
mainMod     = "SUPER"
terminal    = "kitty"
fileManager = "thunar"
menu        = "hyprlauncher"
wallpaper   = "/home/adrien/.config/hypr/wallpapers/ToriPixel.png"

local cfg = os.getenv("HOME") .. "/.config/hypr/"

dofile(cfg .. "monitors.lua")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

dofile(cfg .. "env.lua")
dofile(cfg .. "autostart.lua")
dofile(cfg .. "config.lua")
dofile(cfg .. "animations.lua")
dofile(cfg .. "gestures.lua")
dofile(cfg .. "rules.lua")
dofile(cfg .. "binds.lua")
dofile(cfg .. "plugins.lua")
