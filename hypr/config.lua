hl.config({ xwayland = { force_zero_scaling = true } })

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border   = "rgba(C8D1E9ff)",
            inactive_border = "rgba(01010Fcc)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding         = 8,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000066)",
        },
        blur = {
            enabled           = true,
            size              = 10,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = false,
        },
    },

    animations = { enabled = true },

    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        kb_options = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            drag_lock            = false,
            disable_while_typing = true,
        },
    },

    gestures = {
        workspace_swipe_invert       = false,
        workspace_swipe_distance     = 250,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_forever      = false,
    },

    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        focus_on_activate        = false,
    },
})
