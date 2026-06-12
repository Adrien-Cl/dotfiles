-- Apps
hl.bind("SUPER + Q", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + R", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("quickshell ipc call bar toggleSettings"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))

-- Gestion fenêtres
hl.bind("SUPER + C",       hl.dsp.window.close())
hl.bind("SUPER + V",       hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F",       hl.dsp.window.fullscreen())
hl.bind("SUPER + P",       hl.dsp.window.pin())
hl.bind("SUPER + ALT + C", hl.dsp.window.center())
hl.bind("SUPER + J",       hl.dsp.layout("togglesplit"))

-- ALT+TAB
hl.bind("ALT + Tab",         hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Focus
hl.bind("SUPER + left",  hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up",    hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down",  hl.dsp.focus({ direction = "down" }))

-- Déplacer fenêtre
hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

-- Redimensionner
hl.bind("SUPER + ALT + left",  hl.dsp.window.resize({ x = -40, y = 0 }), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize({ x =  40, y = 0 }), { repeating = true })
hl.bind("SUPER + ALT + up",    hl.dsp.window.resize({ x = 0, y = -40 }), { repeating = true })
hl.bind("SUPER + ALT + down",  hl.dsp.window.resize({ x = 0, y =  40 }), { repeating = true })

-- Workspace cycle
hl.bind("SUPER + Prior",       hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + Next",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind("SUPER + "         .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
    hl.bind("SUPER + CTRL + "  .. i, hl.dsp.window.move({ workspace = i, silent = true }))
end

-- Scratchpad
hl.bind("SUPER + S",         hl.dsp.workspace.toggle_special("special"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))

-- Molette souris → workspace
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Souris — déplacer / redimensionner fenêtre flottante
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true })

-- Luminosité
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Screenshots
hl.bind("Print",                 hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("SUPER + Print",         hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%s).png"))

-- Média
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Presse-papier
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
