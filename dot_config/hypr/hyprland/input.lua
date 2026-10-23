-- input.lua 
-- https://wiki.hypr.land/Configuring/Variables/#input

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    repeat_delay = 300,
    repeat_rate = 50,
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse= 1,
    sensitivity = 0.15, -- -1.0 - 1.0, 0 means no modification. Values outside the range are invalid.
    accel_profile = "adaptive", -- slow moves stay precise, fast moves travel far (libinput default)
    touchpad = {
      natural_scroll = false,
      scroll_factor = 0.35, -- libinput default (1.0) scrolls way too far per swipe; ~0.35 feels close to macOS
      clickfinger_behavior = true, -- macOS-like: 2-finger click = right, 3-finger = middle
      tap_to_click = true,
      disable_while_typing = true,
    },
  },
  gestures = {
    workspace_swipe_distance = 400, -- longer travel = swipe follows the fingers more closely
    workspace_swipe_cancel_ratio = 0.3, -- commit the switch after 30% of the distance
    workspace_swipe_min_speed_to_force = 15, -- a quick flick switches, like macOS
    workspace_swipe_direction_lock = true,
  },
  })


-- Gesture
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
  })


-- Per-device config
-- For an external gaming mouse, flat (no accel) is usually more precise;
-- keep touchpads on adaptive, flat makes small movements imprecise.
-- hl.device({
--   name = "epic-mouse-v1",
--   accel_profile = "flat",
--   sensitivity = 0,
--   })
