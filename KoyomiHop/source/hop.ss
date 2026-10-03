#inc_start
#property $px
#property $py
#property $vx
#property $vy
#property $camera
#property $peak
#property $height_base
#property $height
#property $score
#property $letters
#property $bounces
#property $top
#property $anchor
#property $row
#property $last_platform_kind
#property $ordinary_run
#property $previous_x
#property $alive
#property $accumulator
#property $sound
#property $pulse
#property $dust_x
#property $dust_y
#property $dust_kind
#property $tick
#property $face
#property $flight_ticks
#property $flights
#property $bike_next_height
#property $wind_vx
#property $wind_strength
#property $wind_target
#property $wind_bias
#property $wind_pending
#property $wind_timer
#property $wind_warning
#property $wind_cycle
#property $wind_mode
#property $wind_offset
#property $wind_direction
#property $platform_x : intlist[36]
#property $platform_y : intlist[36]
#property $platform_kind : intlist[36]
#property $platform_live : intlist[36]
#property $platform_speed : intlist[36]
#property $platform_half_width : intlist[36]
#property $platform_letter : intlist[36]
#property $platform_bike : intlist[36]
#property $mode
#property $previous_mode
#property $now
#property $last_time
#property $elapsed
#property $direction
#property $input_active
#property $action_pause
#property $action_confirm
#property $action_restart
#property $action_back
#property $action_exit
#property $action_mute
#property $request_start
#property $request_title
#property $request_exit
#property $hover
#property $best_before
#property $muted
#property $i
#property $sy
#property $sx
#property $pattern
#property $total
#inc_end


#z00
// Only native engine primitives; no novel system/menu scene dependency.
close
syscom.set_syscom_menu_disable
syscom.set_save_enable_flag(0)
syscom.set_hide_mwnd_enable_flag(0)
script.set_auto_savepoint_off
script.set_msg_back_disable
script.set_ctrl_skip_disable
script.set_allow_joypad_mode_onoff(1)
syscom.set_auto_mode_onoff_flag(0)
syscom.set_read_skip_onoff_flag(0)
syscom.set_auto_skip_onoff_flag(0)
$muted = G[1]
$set_sound
$create_stage
$reset_run
$mode = 0
$previous_mode = -1
counter[0].start_real
$last_time = counter[0].get
input.clear
while (1)
{
    $now = counter[0].get
    $elapsed = $now - $last_time
    $last_time = $now
    $hover = -1
    $read_controls
    $route_controls
    if ($action_mute)
    {
        $muted = 1 - $muted
        G[1] = $muted
        $set_sound
    }
    if ($request_start)
    {
        $start_run
    }
    elseif ($request_title)
    {
        $reset_run
    }
    elseif ($request_exit)
    {
        bgm.stop(300)
        owari
    }
    if ($mode == 1)
    {
        $advance($elapsed, $direction)
        if ($score > G[0])
        {
            G[0] = $score
        }
        if ($alive == 0)
        {
            $mode = 3
            $accumulator = 0
        }
    }
    $render_stage
    if ($mode != $previous_mode)
    {
        $show_overlay
        $previous_mode = $mode
    }
    $render_buttons
    if ($sound > 0)
    {
        if ($muted == 0)
        {
            switch ($sound)
            {
                case (1) pcmch[0].play("ph_bounce")
                case (2) pcmch[0].play("ph_boost")
                case (3) pcmch[1].play("ph_star")
                case (4) pcmch[0].play("ph_break")
                case (5) pcmch[2].play("ph_fall")
                case (6) pcmch[2].play("ph_flight")
            }
        }
        $sound = 0
    }
    input.next
    disp
}

command $in_box(property $left, property $top_y, property $right, property $bottom) : int
{
    return (mouse.get_pos_x >= $left && mouse.get_pos_x < $right && mouse.get_pos_y >= $top_y && mouse.get_pos_y < $bottom)
}

command $start_run
{
    $best_before = G[0]
    $reset_run
    $mode = 1
    $elapsed = 0
    $accumulator = 0
    $last_time = counter[0].get
    G[2] += 1
}

command $set_sound
{
    if ($muted == 1)
    {
        syscom.set_all_volume(0)
    }
    else
    {
        syscom.set_all_volume(210)
    }
}


// Native joypad indices follow anemoi's existing __lib_define.inc.
// D-pad: left=2/right=3; left stick digital directions=18/19.
// A/cross=4, B/circle=5, X/square=6, Y/triangle=7, Start=12, Back=13.
// Engine direction keys provide the stick deadzone; no guessed analog units.
command $read_controls
{
    $input_active = system.check_active
    $direction = 0
    $action_pause = 0
    $action_confirm = 0
    $action_restart = 0
    $action_back = 0
    $action_exit = 0
    $action_mute = 0
    if ($input_active == 0)
    {
        return
    }
    if (key[37].is_down || key['A'].is_down || joypad.key[2].is_down || joypad.key[18].is_down)
    {
        $direction -= 1
    }
    if (key[39].is_down || key['D'].is_down || joypad.key[3].is_down || joypad.key[19].is_down)
    {
        $direction += 1
    }
    $action_pause = key['P'].on_down || key[27].on_down || joypad.key[12].on_down || mouse.right.on_down || (mouse.left.on_down && $in_box(684, 750, 924, 796))
    $action_confirm = key[32].on_down || key[13].on_down || joypad.key[4].on_down
    if (mouse.left.on_down && (($mode == 2 && $in_box(128, 514, 512, 578)) || ($mode != 2 && $in_box(128, 548, 512, 612))))
    {
        $action_confirm = 1
    }
    $action_restart = key['R'].on_down || (($mode == 2 || $mode == 3) && joypad.key[6].on_down) || ($mode == 2 && mouse.left.on_down && $in_box(128, 592, 512, 646))
    $action_back = key['Q'].on_down || joypad.key[5].on_down || joypad.key[13].on_down || (mouse.left.on_down && $in_box(208, 667, 432, 713))
    $action_exit = key['X'].on_down || key[27].on_down || joypad.key[5].on_down || (mouse.left.on_down && $in_box(208, 638, 432, 688))
    $action_mute = key['M'].on_down || joypad.key[7].on_down || (mouse.left.on_down && $in_box(684, 810, 924, 856))
}

// One transition per frame: holding confirm cannot restart after a death,
// and returning to the title cannot also quit on the same B press.
command $route_controls
{
    $request_start = 0
    $request_title = 0
    $request_exit = 0
    if ($input_active == 0)
    {
        if ($mode == 1)
        {
            $mode = 2
        }
        $elapsed = 0
        $accumulator = 0
    }
    elseif ($mode == 1 && $action_pause)
    {
        $mode = 2
        $accumulator = 0
    }
    elseif ($mode == 2 && ($action_pause || $action_confirm))
    {
        $mode = 1
        $elapsed = 0
        $accumulator = 0
    }
    elseif (($mode == 0 || $mode == 3) && $action_confirm)
    {
        $request_start = 1
    }
    elseif ($mode != 0 && $action_restart)
    {
        $request_start = 1
    }
    elseif (($mode == 2 || $mode == 3) && $action_back)
    {
        $mode = 0
        $accumulator = 0
        $request_title = 1
    }
    elseif ($mode == 0 && $action_exit)
    {
        $request_exit = 1
    }
}


// Pure Siglus physics. Units: 1000 = one pixel, +Y = upwards.
// All four platform kinds share one stream; there is no protected ordinary spine.
command $new_row(property $slot)
{
    property $gap
    property $route_height
    property $difficulty
    property $normal_weight
    property $moving_weight
    property $fragile_weight
    property $kind_roll
    property $candidate
    property $best_x
    property $penalty
    property $best_penalty
    property $attempt
    property $j
    property $dx
    $route_height = math.limit(0, $height_base + ($top - 80000) / 10000, 50000)
    $difficulty = $route_height * 1000 / ($route_height + 800)
    // Smoothly trade ordinary footholds for moving and one-use footholds.
    // Initial weights: 58/14/8/20; high-altitude limits: 42/24/14/20.
    $normal_weight = 580 - $difficulty * 160 / 1000
    $moving_weight = 140 + $difficulty * 100 / 1000
    $fragile_weight = 1000 - $normal_weight - $moving_weight - 200
    $kind_roll = math.rand(0, 999)
    if ($ordinary_run >= 3)
    {
        $kind_roll = $normal_weight + math.rand(0, 999) * (1000 - $normal_weight) / 1000
    }
    $platform_kind[$slot] = 0
    if ($kind_roll >= $normal_weight)
    {
        $platform_kind[$slot] = 1
    }
    if ($kind_roll >= $normal_weight + $moving_weight)
    {
        $platform_kind[$slot] = 2
    }
    if ($kind_roll >= $normal_weight + $moving_weight + $fragile_weight)
    {
        $platform_kind[$slot] = 3
    }
    $gap = 88000 + $difficulty * 18 + math.rand(0, 1000) * (50000 - $difficulty * 12) / 1000
    // A spring opens a visibly larger empty stretch, using its higher jump.
    if ($last_platform_kind == 3)
    {
        $gap = 185000 + $difficulty * 15 + math.rand(0, 1000) * 65000 / 1000
    }
    // Two introductory landings only; the mixed stream begins immediately after.
    if ($row < 3)
    {
        $platform_kind[$slot] = 0
        $gap = 75000 + math.rand(0, 1000) * 30000 / 1000
    }
    $top += $gap
    $platform_half_width[$slot] = 61000
    if ($platform_kind[$slot] == 0 && $row >= 3)
    {
        $platform_half_width[$slot] = 45000 + math.rand(0, 2) * 8000
    }
    // Global full-width samples: no anchor corridor or worst-wind reach solver.
    // Avoid ordinary platforms sharing a recent column; never add a rescue row.
    $best_penalty = 2000000000
    $attempt = 0
    while ($attempt < 10 && $best_penalty > 0)
    {
        $candidate = 66000 + math.rand(0, 1000) * 508
        if ($row < 3)
        {
            $candidate = $anchor - 110000 + math.rand(0, 1000) * 220
        }
        $penalty = 0
        // Only discourage extreme empty crossings on a regular jump.
        // This broad, wrap-aware preference is independent of wind/width and
        // does not guarantee a landing from the centre or a neutral start.
        if ($last_platform_kind != 3)
        {
            $dx = math.abs($candidate - $anchor)
            $dx = math.min($dx, 640000 - $dx)
            $penalty += math.max(0, $dx - 250000) * 4
        }
        if ($platform_kind[$slot] == 0)
        {
            for ($j = 0, $j < 36, $j += 1)
            {
                if ($j != $slot && $platform_live[$j] == 1 && $platform_kind[$j] == 0 && math.abs($top - $platform_y[$j]) < 650000)
                {
                    $dx = math.abs($candidate - $platform_x[$j])
                    $dx = math.min($dx, 640000 - $dx)
                    $penalty += math.max(0, 110000 - $dx)
                }
            }
        }
        if (math.abs($candidate - $anchor) < 55000 && math.abs($candidate - $previous_x) < 55000)
        {
            $penalty += 110000
        }
        if ($penalty < $best_penalty)
        {
            $best_penalty = $penalty
            $best_x = $candidate
        }
        $attempt += 1
    }
    $previous_x = $anchor
    $anchor = $best_x
    $last_platform_kind = $platform_kind[$slot]
    // Track consecutive kinds from the actual generated sequence.
    if ($last_platform_kind == 0)
    {
        $ordinary_run += 1
    }
    else
    {
        $ordinary_run = 0
    }
    $platform_x[$slot] = $anchor
    $platform_y[$slot] = $top
    $platform_live[$slot] = 1
    $platform_speed[$slot] = 0
    if ($platform_kind[$slot] == 1)
    {
        $platform_speed[$slot] = 850 + $difficulty * 950 / 1000
        if (math.rand(0, 1) == 0)
        {
            $platform_speed[$slot] = -$platform_speed[$slot]
        }
    }
    $platform_letter[$slot] = 0
    if (math.rand(0, 99) < 35)
    {
        $platform_letter[$slot] = 1
    }
    // A height-spaced power-up replaces the letter on a stable foothold.
    // Absolute height survives coordinate rebasing; no extra platforms are added.
    $platform_bike[$slot] = 0
    if ($route_height >= $bike_next_height && $platform_kind[$slot] != 2 && $row >= 3)
    {
        $platform_bike[$slot] = 1
        $platform_letter[$slot] = 0
        $bike_next_height = $height_base + ($top - 80000) / 10000 + 850 + math.rand(0, 400)
    }
    $row += 1
}

command $reset_run
{
    property $j
    $px = 320000
    $py = 80000
    $vx = 0
    $vy = 10800
    $camera = 0
    $peak = 80000
    $height_base = 0
    $height = 0
    $score = 0
    $letters = 0
    $bounces = 0
    $top = 80000
    $anchor = 320000
    $row = 1
    $last_platform_kind = 0
    $ordinary_run = 0
    $previous_x = 320000
    $alive = 1
    $accumulator = 0
    $sound = 0
    $pulse = 0
    $tick = 0
    $face = 0
    $flight_ticks = 0
    $flights = 0
    $bike_next_height = 120 + math.rand(0, 80)
    $wind_vx = 0
    $wind_strength = 0
    $wind_target = 0
    $wind_bias = 0
    $wind_pending = 0
    $wind_timer = 0
    $wind_warning = 0
    $wind_cycle = 3
    $wind_mode = 0
    $wind_offset = 0
    $wind_direction = math.rand(0, 1) * 2 - 1
    for ($j = 0, $j < 36, $j += 1)
    {
        $platform_x[$j] = 320000
        $platform_y[$j] = -100000
        $platform_kind[$j] = 0
        $platform_live[$j] = 0
        $platform_speed[$j] = 0
        $platform_half_width[$j] = 61000
        $platform_letter[$j] = 0
        $platform_bike[$j] = 0
    }
    $platform_x[0] = 320000
    $platform_y[0] = 80000
    $platform_live[0] = 1
    for ($j = 1, $j < 36, $j += 1)
    {
        $new_row($j)
    }
}

command $update_wind
{
    property $altitude
    property $gust_mix
    property $gust
    if ($height <= 250)
    {
        $wind_strength = 0
        $wind_vx = 0
        $wind_mode = 0
        return
    }
    $altitude = math.limit(0, $height - 250, 50000)
    // 0 at 250 m; half strength at 750 m; approaches 1.8 px/tick.
    // Controls remain 5.2 px/tick and the forecast/slew still prevents impulses.
    $wind_strength = $altitude * 1800 / ($altitude + 500)
    // Variable direction blends in continuously from 900 to 1500 m.
    $gust_mix = math.limit(0, $height - 900, 600) * 1000 / 600
    $wind_timer -= 1
    if ($wind_timer <= 0)
    {
        $wind_cycle = ($wind_cycle + 1) % 4
        $wind_pending = $wind_direction * 1000
        if ($wind_cycle >= 2 && $gust_mix > 0)
        {
            $gust = math.rand(0, 1000) * 2 - 1000
            $wind_pending = ($wind_direction * (1000 - $gust_mix) * 1000 + $gust * $gust_mix) / 1000
        }
        // Display the next direction for a full second before changing it.
        $wind_warning = 63
        $wind_timer = 250
    }
    $wind_mode = 1
    if ($wind_cycle >= 2 && $gust_mix > 0)
    {
        $wind_mode = 2
    }
    if ($wind_warning > 0)
    {
        $wind_warning -= 1
        if ($wind_warning == 0)
        {
            $wind_bias = $wind_pending
        }
    }
    $wind_target = $wind_strength * $wind_bias / 1000
    // Slew through zero when reversing; no instantaneous sideways impulse.
    $wind_vx += math.limit(-20, $wind_target - $wind_vx, 20)
    $wind_offset = ($wind_offset + $wind_vx + 760000) % 760000
}

command $physics_step(property $axis)
{
    property $j
    property $old_y
    property $hit
    property $hit_y
    property $dx
    property $dy
    property $flight_target
    property $item_y
    if ($alive == 0)
    {
        return
    }
    $tick += 1
    $update_wind
    $pulse = math.limit(0, $pulse - 1, 18)
    $axis = math.limit(-1, $axis, 1)
    if ($axis == 0)
    {
        if ($vx > 0)
        {
            $vx = math.limit(0, $vx - 520, 5200)
        }
        elseif ($vx < 0)
        {
            $vx = math.limit(-5200, $vx + 520, 0)
        }
    }
    else
    {
        $vx = math.limit(-5200, $vx + $axis * 700, 5200)
        $face = 0
        if ($axis < 0)
        {
            $face = 1
        }
    }
    // Wind is an independent drift, never folded into the player's speed cap.
    $px += $vx + $wind_vx
    if ($px < 0)
    {
        $px += 640000
    }
    elseif ($px >= 640000)
    {
        $px -= 640000
    }
    for ($j = 0, $j < 36, $j += 1)
    {
        if ($platform_live[$j] == 1 && $platform_kind[$j] == 1)
        {
            $platform_x[$j] += $platform_speed[$j]
            if ($platform_x[$j] < 66000)
            {
                $platform_x[$j] = 66000
                $platform_speed[$j] = math.abs($platform_speed[$j])
            }
            elseif ($platform_x[$j] > 574000)
            {
                $platform_x[$j] = 574000
                $platform_speed[$j] = -math.abs($platform_speed[$j])
            }
        }
    }
    $old_y = $py
    if ($flight_ticks > 0)
    {
        // Four seconds at the fixed 16 ms step. Ramp in, then spend the last
        // 0.8 seconds easing back to ordinary take-off speed for a safe handoff.
        $flight_ticks -= 1
        $flight_target = 28000
        if ($flight_ticks < 50)
        {
            $flight_target = 10800 + $flight_ticks * 344
        }
        $vy += math.limit(-380, $flight_target - $vy, 900)
    }
    else
    {
        $vy -= 380
        $vy = math.limit(-19000, $vy, 17500)
    }
    $py += $vy
    $hit = -1
    $hit_y = -2000000000
    if ($vy < 0)
    {
        for ($j = 0, $j < 36, $j += 1)
        {
            if ($platform_live[$j] == 1 && $old_y >= $platform_y[$j] && $py <= $platform_y[$j])
            {
                $dx = math.abs($px - $platform_x[$j])
                $dx = math.min($dx, 640000 - $dx)
                if ($dx <= $platform_half_width[$j] + 10000 && $platform_y[$j] > $hit_y)
                {
                    $hit = $j
                    $hit_y = $platform_y[$j]
                }
            }
        }
    }
    if ($hit >= 0)
    {
        $py = $hit_y
        $vy = 10800
        $sound = 1
        $dust_kind = 0
        $bounces += 1
        if ($platform_kind[$hit] == 3)
        {
            $vy = 17500
            $sound = 2
            $dust_kind = 1
        }
        elseif ($platform_kind[$hit] == 2)
        {
            $platform_live[$hit] = 0
            $sound = 4
            $dust_kind = 2
        }
        $dust_x = $px
        $dust_y = $py
        $pulse = 18
    }
    for ($j = 0, $j < 36, $j += 1)
    {
        if ($platform_letter[$j] == 1)
        {
            $dx = math.abs($px - $platform_x[$j])
            $dx = math.min($dx, 640000 - $dx)
            $item_y = $platform_y[$j] + 55000
            // Sweep the pickup body vertically, including the high-speed flight.
            if ($dx < 35000 && $item_y >= math.min($old_y, $py) + 8000 && $item_y <= math.max($old_y, $py) + 80000)
            {
                $platform_letter[$j] = 0
                $letters += 1
                if ($sound != 6)
                {
                    $sound = 3
                }
            }
        }
        if ($platform_bike[$j] == 1 && $flight_ticks == 0)
        {
            $dx = math.abs($px - $platform_x[$j])
            $dx = math.min($dx, 640000 - $dx)
            $item_y = $platform_y[$j] + 56000
            if ($dx < 44000 && $item_y >= math.min($old_y, $py) + 4000 && $item_y <= math.max($old_y, $py) + 84000)
            {
                $platform_bike[$j] = 0
                $flight_ticks = 250
                $flights += 1
                $vy = math.max($vy, 10800)
                $pulse = 0
                $sound = 6
            }
        }
    }
    $peak = math.max($peak, $py)
    $camera = math.max($camera, $py - 540000)
    $height = $height_base + ($peak - 80000) / 10000
    $score = math.limit(0, $height + $letters * 25, 999999)
    // Keep long sessions away from Siglus signed-32-bit coordinate overflow.
    if ($camera > 500000000)
    {
        $py -= 400000000
        $peak -= 400000000
        $camera -= 400000000
        $top -= 400000000
        $dust_y -= 400000000
        $height_base += 40000
        for ($j = 0, $j < 36, $j += 1)
        {
            $platform_y[$j] -= 400000000
        }
    }
    for ($j = 0, $j < 36, $j += 1)
    {
        if ($platform_y[$j] < $camera - 80000)
        {
            $new_row($j)
        }
    }
    if ($py < $camera - 90000)
    {
        $alive = 0
        $sound = 5
    }
}

command $advance(property $ms, property $axis)
{
    $accumulator += math.limit(0, $ms, 80)
    while ($accumulator >= 16 && $alive == 1)
    {
        $physics_step($axis)
        $accumulator -= 16
    }
}


command $create_stage
{
    property $j
    for ($j = 0, $j < 210, $j += 1)
    {
        front.object[$j].init
    }
    front.object[0].create("ph_paper", 1, 0, 0)
    front.object[0].layer = 0
    for ($j = 0, $j < 3, $j += 1)
    {
        front.object[1 + $j].create("ph_cloud", 1, 70 + $j * 178, 110 + $j * 287)
        front.object[1 + $j].layer = 1
    }
    for ($j = 0, $j < 36, $j += 1)
    {
        front.object[20 + $j].create("ph_platform", 0, 0, 0)
        front.object[20 + $j].layer = 10
        front.object[60 + $j].create("ph_letter", 0, 0, 0)
        front.object[60 + $j].layer = 12
        front.object[120 + $j].create("ph_bicycle", 0, 0, 0)
        front.object[120 + $j].layer = 13
    }
    front.object[100].create("ph_hero", 1, 288, 754)
    front.object[100].layer = 20
    front.object[101].create("ph_hero", 0, 0, 0)
    front.object[101].layer = 20
    front.object[102].create("ph_bird", 0, 0, 0)
    front.object[102].layer = 21
    front.object[104].create("ph_bird", 0, 0, 0)
    front.object[104].layer = 21
    front.object[105].create("ph_flight_trail", 0, 0, 0)
    front.object[105].layer = 18
    front.object[106].create("ph_flight_trail", 0, 0, 0)
    front.object[106].layer = 18
    front.object[103].create("ph_dust", 0, 0, 0)
    front.object[103].layer = 19
    for ($j = 0, $j < 5, $j += 1)
    {
        front.object[110 + $j].create("ph_wind_streak", 0, 0, 0)
        front.object[110 + $j].layer = 2
    }
    front.object[160].create("ph_sidebar", 1, 640, 0)
    front.object[160].layer = 100
    front.object[161].create_number("ph_digits", 1, 682, 154)
    front.object[161].set_number_param(6, 1, 0, 0, 0, 0)
    front.object[161].layer = 101
    front.object[162].create_number("ph_digits_small", 1, 684, 280)
    front.object[162].set_number_param(5, 1, 0, 0, 0, 0)
    front.object[162].layer = 101
    front.object[163].create_number("ph_digits_small", 1, 841, 280)
    front.object[163].set_number_param(3, 1, 0, 0, 0, 0)
    front.object[163].layer = 101
    front.object[164].create_number("ph_digits_small", 1, 684, 382)
    front.object[164].set_number_param(6, 1, 0, 0, 0, 0)
    front.object[164].layer = 101
    front.object[165].create("ph_stage", 1, 680, 436)
    front.object[165].layer = 101
    front.object[166].create("ph_side_pause", 1, 684, 750)
    front.object[166].layer = 101
    front.object[167].create("ph_sound", 1, 684, 810)
    front.object[167].layer = 101
    front.object[168].create("ph_wind_meter", 1, 680, 496)
    front.object[168].layer = 101
    front.object[169].create("ph_wind_hint", 1, 680, 542)
    front.object[169].layer = 101
    front.object[170].create("ph_flight_hud", 0, 680, 436)
    front.object[170].layer = 102
    front.object[171].create("ph_flight_bar", 0, 692, 478)
    front.object[171].layer = 103
    front.object[190].create_rect(0, 0, 640, 900, 36, 63, 66, 105, 0)
    front.object[190].layer = 200
    front.object[191].create("ph_title", 1, 0, 0)
    front.object[191].layer = 201
    front.object[192].create("ph_primary", 1, 128, 548)
    front.object[192].layer = 202
    front.object[193].create("ph_secondary", 1, 208, 638)
    front.object[193].layer = 202
    front.object[194].create_number("ph_digits", 0, 224, 386)
    front.object[194].set_number_param(6, 1, 0, 0, 0, 0)
    front.object[194].layer = 203
    front.object[195].create("ph_record", 0, 202, 475)
    front.object[195].layer = 203
    front.object[196].create("ph_restart", 0, 128, 592)
    front.object[196].layer = 202
    bgm.play("ph_music", 1000)
}

command $render_stage
{
    property $j
    property $screen_y
    property $screen_x
    property $hero_pattern
    property $phase
    property $bird_pattern
    property $flight_alpha
    for ($j = 0, $j < 3, $j += 1)
    {
        front.object[1 + $j].y = (110 + $j * 287 + $camera / 5000) % 1100 - 100
    }
    for ($j = 0, $j < 5, $j += 1)
    {
        front.object[110 + $j].disp = 0
        if (math.abs($wind_vx) > 60)
        {
            front.object[110 + $j].disp = 1
            front.object[110 + $j].patno = 0
            if ($wind_vx < 0)
            {
                front.object[110 + $j].patno = 1
            }
            front.object[110 + $j].tr = math.limit(30, math.abs($wind_vx) / 12, 125)
            front.object[110 + $j].set_pos(($wind_offset / 1000 + $j * 149) % 760 - 110, 140 + $j * 143)
        }
    }
    for ($j = 0, $j < 36, $j += 1)
    {
        $screen_y = 900 - ($platform_y[$j] - $camera) / 1000
        $screen_x = $platform_x[$j] / 1000
        front.object[20 + $j].disp = 0
        front.object[60 + $j].disp = 0
        front.object[120 + $j].disp = 0
        if ($screen_y > -90 && $screen_y < 960)
        {
            front.object[20 + $j].disp = $platform_live[$j]
            front.object[20 + $j].patno = $platform_kind[$j]
            if ($platform_kind[$j] == 0 && $platform_half_width[$j] < 61000)
            {
                front.object[20 + $j].patno = 4 + ($platform_half_width[$j] - 45000) / 8000
            }
            front.object[20 + $j].set_pos($screen_x - 64, $screen_y - 8)
            front.object[60 + $j].disp = $platform_letter[$j]
            front.object[60 + $j].patno = ($tick / 12) % 2
            front.object[60 + $j].set_pos($screen_x - 19, $screen_y - 74)
            front.object[120 + $j].disp = $platform_bike[$j]
            front.object[120 + $j].patno = ($tick / 16) % 2
            front.object[120 + $j].set_pos($screen_x - 34, $screen_y - 88)
        }
    }
    $screen_x = $px / 1000 - 40
    $screen_y = 900 - ($py - $camera) / 1000 - 90
    $hero_pattern = $face * 3
    // Keep the last direction when the player releases a key. A neutral fall
    // can use the existing open-arm pose; directional airtime uses the new art.
    if ($vy < 0 && math.abs($vx) < 700)
    {
        $hero_pattern = 1
    }
    if ($pulse > 13)
    {
        $hero_pattern = 2
    }
    front.object[100].set_pos($screen_x, $screen_y)
    front.object[100].patno = $hero_pattern
    front.object[100].disp = 1
    front.object[100].tr = 255
    front.object[101].disp = 0
    if ($px < 40000)
    {
        front.object[101].disp = 1
        front.object[101].set_pos($screen_x + 640, $screen_y)
    }
    elseif ($px > 600000)
    {
        front.object[101].disp = 1
        front.object[101].set_pos($screen_x - 640, $screen_y)
    }
    front.object[101].patno = $hero_pattern
    front.object[101].tr = 255
    front.object[102].disp = 0
    front.object[104].disp = 0
    front.object[105].disp = 0
    front.object[106].disp = 0
    front.object[170].disp = 0
    front.object[171].disp = 0
    if ($flight_ticks > 0)
    {
        // Blend the human/bird body at entry and exit without moving its centre.
        $flight_alpha = math.limit(0, math.min(250 - $flight_ticks, $flight_ticks) * 255 / 12, 255)
        front.object[100].tr = 255 - $flight_alpha
        front.object[101].tr = 255 - $flight_alpha
        $bird_pattern = ($tick / 5) % 4
        if ($bird_pattern == 3)
        {
            $bird_pattern = 1
        }
        $screen_x = $px / 1000 - 56
        $screen_y = 900 - ($py - $camera) / 1000 - 88
        front.object[102].set_pos($screen_x, $screen_y)
        front.object[102].patno = $bird_pattern
        front.object[102].tr = $flight_alpha
        front.object[102].disp = 1
        front.object[105].set_pos($screen_x, $screen_y + 56)
        front.object[105].patno = ($tick / 4) % 3
        front.object[105].tr = $flight_alpha * 3 / 4
        front.object[105].disp = 1
        if ($px < 56000 || $px > 584000)
        {
            if ($px < 56000)
            {
                $screen_x += 640
            }
            else
            {
                $screen_x -= 640
            }
            front.object[104].set_pos($screen_x, $screen_y)
            front.object[104].patno = $bird_pattern
            front.object[104].tr = $flight_alpha
            front.object[104].disp = 1
            front.object[106].set_pos($screen_x, $screen_y + 56)
            front.object[106].patno = ($tick / 4) % 3
            front.object[106].tr = $flight_alpha * 3 / 4
            front.object[106].disp = 1
        }
        front.object[170].disp = 1
        front.object[170].patno = 0
        if ($flight_ticks <= 50)
        {
            front.object[170].patno = 1
        }
        front.object[171].disp = 1
        front.object[171].scale_x = $flight_ticks * 4
    }
    front.object[103].disp = 0
    if ($pulse > 0)
    {
        front.object[103].disp = 1
        front.object[103].patno = $dust_kind
        front.object[103].tr = $pulse * 14
        front.object[103].set_pos($dust_x / 1000 - 48, 900 - ($dust_y - $camera) / 1000 - 15 + (18 - $pulse))
    }
    front.object[161].set_number($score)
    front.object[162].set_number(math.limit(0, $height, 99999))
    front.object[163].set_number(math.limit(0, $letters, 999))
    front.object[164].set_number(G[0])
    $phase = 0
    if ($height > 250)
    {
        $phase = 1
    }
    if ($height >= 900)
    {
        $phase = 2
    }
    front.object[165].patno = $phase
    front.object[168].patno = 0
    if ($wind_vx != 0)
    {
        front.object[168].patno = math.limit(1, (math.abs($wind_vx) + 224) / 225, 8)
        if ($wind_vx < 0)
        {
            front.object[168].patno += 8
        }
    }
    front.object[169].patno = 0
    if ($wind_mode > 0)
    {
        front.object[169].patno = 2 + $wind_mode
        if ($wind_warning > 0)
        {
            front.object[169].patno = 5
            if ($wind_pending < 0)
            {
                front.object[169].patno = 1
            }
            elseif ($wind_pending > 0)
            {
                front.object[169].patno = 2
            }
        }
    }
    front.object[167].patno = $muted * 2
    if ($in_box(684, 810, 924, 856))
    {
        front.object[167].patno += 1
    }
    front.object[166].patno = 0
    front.object[166].disp = 0
    if ($mode == 1 || $mode == 2)
    {
        front.object[166].disp = 1
        if ($mode == 2)
        {
            front.object[166].patno = 2
        }
        if ($in_box(684, 750, 924, 796))
        {
            front.object[166].patno += 1
        }
    }
}

command $show_overlay
{
    front.object[190].disp = 1
    front.object[191].disp = 1
    front.object[192].disp = 1
    front.object[193].disp = 1
    front.object[194].disp = 0
    front.object[195].disp = 0
    front.object[196].disp = 0
    if ($mode == 1)
    {
        front.object[190].disp = 0
        front.object[191].disp = 0
        front.object[192].disp = 0
        front.object[193].disp = 0
    }
    elseif ($mode == 0)
    {
        front.object[191].create("ph_title", 1, 0, 0)
        front.object[192].set_pos(128, 548)
        front.object[193].set_pos(208, 638)
    }
    elseif ($mode == 2)
    {
        front.object[191].create("ph_pause", 1, 0, 0)
        front.object[192].set_pos(128, 514)
        front.object[193].set_pos(208, 667)
        front.object[196].disp = 1
    }
    elseif ($mode == 3)
    {
        front.object[191].create("ph_over", 1, 0, 0)
        front.object[192].set_pos(128, 548)
        front.object[193].set_pos(208, 667)
        front.object[194].disp = 1
        front.object[194].set_number($score)
        if ($score > $best_before)
        {
            front.object[195].disp = 1
        }
    }
    front.object[191].layer = 201
}

command $render_buttons
{
    property $inside
    $inside = 0
    if ($mode == 2)
    {
        $inside = $in_box(128, 514, 512, 578)
        front.object[192].patno = 2 + $inside
    }
    elseif ($mode == 3)
    {
        $inside = $in_box(128, 548, 512, 612)
        front.object[192].patno = 4 + $inside
    }
    else
    {
        $inside = $in_box(128, 548, 512, 612)
        front.object[192].patno = $inside
    }
    if ($mode == 0)
    {
        front.object[193].patno = $in_box(208, 638, 432, 688)
    }
    else
    {
        front.object[193].patno = 2 + $in_box(208, 667, 432, 713)
    }
    front.object[196].patno = $in_box(128, 592, 512, 646)
}
