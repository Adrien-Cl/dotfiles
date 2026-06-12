-- Layer rules
hl.layer_rule({
    name         = "quickshell-blur",
    match        = { namespace = "^quickshell$" },
    blur         = true,
    ignore_alpha = 0.5,
})

-- Window rules
hl.window_rule({ name = "brave-ws1",    match = { class = "brave" },                workspace = "1 silent" })
hl.window_rule({ name = "vscodium-ws2", match = { class = "VSCodium" },             workspace = "2 silent" })
hl.window_rule({ name = "kitty-ws3",    match = { class = "kitty" },                workspace = "3 silent" })
hl.window_rule({ name = "vesktop-ws9",  match = { class = "vesktop" },              workspace = "9 silent" })
hl.window_rule({ name = "float-rofi",   match = { class = "rofi" },                 float = true })
hl.window_rule({ name = "float-pavu",   match = { class = "pavucontrol" },          float = true })
hl.window_rule({ name = "float-blue",   match = { class = "blueman-manager" },      float = true })
hl.window_rule({ name = "float-nm",     match = { class = "nm-connection-editor" }, float = true })
hl.window_rule({ name = "float-look",   match = { class = "nwg-look" },             float = true })
