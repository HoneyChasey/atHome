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
    sensitivity = 0, -- -1.0 - 1.0, M means no modifcation. 
    touchpad = {
      natural_scroll = false,
      scroll_factor = 0.6, -- libinput default (1.0) scrolls way too far per swipe
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
-- hl.device({
--   name = "epic-mouse-v1",
--   sensitivity = -0.5,
--   })

hl.config{
  input = { -- config global for all input device. 
    sensitivity = 2.0,
    accel_profile = "flat",
    -- force_no_accel = true, -- use it if really you think there is mouse acceleration
  }
}
