-- rules.lua

-- Ignore maximize requests from all apps
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- No blur behind windows (blur stays on for the quickshell bar layer)
hl.window_rule({
    name    = "no-blur-windows",
    match   = { class = ".*" },
    no_blur = true,
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Quickshell top bar: blur behind the (almost opaque) bar and its popups
hl.layer_rule({
    name         = "blur-quickshell-bar",
    match        = { namespace = "^quickshell-bar$" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.15,
})
