# dotfiles

My personal Hyprland rice on Arch Linux.

## Setup

| Component | Tool |
|-----------|------|
| Compositor | [Hyprland](https://hyprland.org/) |
| Bar | [Quickshell](https://quickshell.outfoxxed.me/) (QML) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Shell | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) |
| App launcher | [Rofi](https://github.com/davatorium/rofi) |
| Lock screen | [Hyprlock](https://github.com/hyprwm/hyprlock) |
| Idle daemon | [Hypridle](https://github.com/hyprwm/hypridle) |
| Wallpaper | [Hyprpaper](https://github.com/hyprwm/hyprpaper) |
| System info | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Font | JetBrainsMono Nerd Font |

## Structure

```
~/.config/
├── hypr/
│   ├── hyprland.lua        # Entry point
│   ├── config.lua          # General settings
│   ├── binds.lua           # Keybindings
│   ├── rules.lua           # Window rules
│   ├── monitors.lua        # Monitor layout
│   ├── animations.lua      # Animations
│   ├── autostart.lua       # Autostart apps
│   ├── env.lua             # Environment variables
│   ├── gestures.lua        # Touchpad gestures
│   ├── plugins.lua         # Hyprland plugins
│   ├── hyprlock.conf       # Lock screen
│   ├── hypridle.conf       # Idle daemon
│   ├── hyprpaper.conf      # Wallpaper
│   └── wallpapers/         # Wallpaper files
├── quickshell/
│   ├── shell.qml           # Entry point
│   ├── Bar.qml             # Top bar
│   ├── theme.qml           # Colors & sizes
│   ├── KdeConnectState.qml # KDE Connect state
│   ├── NotificationState.qml
│   ├── ai_backend.py       # FastAPI backend (Groq / llama-3.3-70b), tools filesystem
│   ├── ai_config.json      # Clé API Groq (groq_api_key)
│   ├── .ai_venv/           # Virtualenv Python (anthropic, fastapi, uvicorn, groq)
│   └── modules/
│       ├── Left.qml        # Left bar section
│       ├── Center.qml      # Center bar section
│       ├── Right.qml       # Right bar section
│       ├── AiChatPanel.qml # Panel IA (icône ★ barre gauche)
│       ├── ControlPanel.qml
│       ├── BluetoothPanel.qml
│       ├── KdeConnectPanel.qml
│       ├── MediaPlayer.qml
│       ├── MediaPopup.qml
│       ├── BatteryPopup.qml
│       ├── Notifications.qml
│       ├── NotificationToasts.qml
│       ├── OSD.qml
│       ├── PowerMenu.qml
│       ├── BarSeparator.qml
│       └── settings/       # Settings panel (8 pages)
├── kitty/kitty.conf
├── fish/
│   ├── config.fish
│   ├── conf.d/
│   └── functions/
├── starship.toml
├── rofi/config.rasi
└── fastfetch/
    ├── config.jsonc
    └── ASCII/
```
