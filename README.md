# dotfiles

My personal Hyprland rice on Arch Linux.

## Setup

| Component | Tool |
|-----------|------|
| Compositor | [Hyprland](https://hyprland.org/) |
| Bar | [Quickshell](https://quickshell.outfoxxed.me/) (QML) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Shell | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) |
| Prompt | Starship |
| App launcher | [Rofi](https://github.com/davatorium/rofi) |
| Lock screen | [Hyprlock](https://github.com/hyprwm/hyprlock) |
| Wallpaper | [Hyprpaper](https://github.com/hyprwm/hyprpaper) |
| SDDM theme | Custom (`sddm-theme-adrien-minimal`) |
| System info | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Font | JetBrainsMono Nerd Font |

## Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf       # Main Hyprland config
│   ├── hyprlock.conf       # Lock screen
│   └── hyprpaper.conf      # Wallpaper
├── quickshell/
│   ├── shell.qml           # Entry point
│   ├── Bar.qml             # Top bar
│   ├── theme.qml           # Colors & sizes
│   └── modules/            # Bar components (left/center/right, panels, OSD…)
├── kitty/kitty.conf
├── fish/config.fish
├── starship.toml
├── rofi/config.rasi
├── fastfetch/config.jsonc
└── sddm-theme-adrien-minimal/
```
