#inc_start
#property $accumulator
#property $action_back
#property $action_confirm
#property $action_exit
#property $action_mute
#property $action_pause
#property $action_restart
#property $board_x
#property $board_y
#property $cells
#property $choices : intlist[4]
#property $direction
#property $distance : intlist[713]
#property $dx : intlist[4]
#property $dy : intlist[4]
#property $elapsed
#property $entry
#property $entry_x
#property $entry_y
#property $exit
#property $exit_x
#property $exit_y
#property $explored
#property $face
#property $floor_count
#property $fog_clock
#property $fog_update_ms
#property $grid : intlist[713]
#property $height
#property $held : intlist[4]
#property $input_active
#property $last_fog
#property $last_time
#property $last_seen : intlist[713]
#property $level
#property $map_dirty
#property $map_visible
#property $mode
#property $muted
#property $now
#property $optimal_steps
#property $pick_level
#property $player_x
#property $player_y
#property $preferred
#property $queue : intlist[713]
#property $request_exit
#property $request_start
#property $seen : intlist[713]
#property $sound
#property $stack : intlist[713]
#property $steps
#property $tile
#property $tile_pattern : intlist[713]
#property $time_ms
#property $to_x
#property $to_y
#property $trail : intlist[713]
#property $walk_ms
#property $visible : intlist[713]
#property $walking
#property $width
#property $won
#inc_end


#z00
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
$level = math.limit(0, G[2], 2)
if (G[3] == 0)
{
    $level = 1
    G[3] = 1
}
$mode = 0
$preferred = 0
$create_stage
$set_sound
counter[0].start_real
$last_time = counter[0].get
input.clear
while (1)
{
    $now = counter[0].get
    $elapsed = $now - $last_time
    $last_time = $now
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
        $make_maze($level)
        $create_map
        $mode = 1
        $elapsed = 0
        $last_time = counter[0].get
        G[2] = $level
        $sound = 2
    }
    if ($request_exit)
    {
        bgm.stop(200)
        owari
    }
    if ($mode == 1)
    {
        $advance($elapsed, $direction)
        if ($won == 1)
        {
            $mode = 3
            $accumulator = 0
            G[0] += 1
            if (G[10 + $level] == 0 || $steps < G[10 + $level])
            {
                G[10 + $level] = $steps
            }
        }
    }
    $render_stage
    $render_ui
    if ($sound > 0)
    {
        if ($muted == 0)
        {
            switch ($sound)
            {
                case (1) pcmch[0].play("sm_step")
                case (2) pcmch[1].play("sm_start")
                case (3) pcmch[1].play("sm_win")
            }
        }
        $sound = 0
    }
    input.next
    disp
}

command $in_box(property $left, property $top, property $right, property $bottom) : int
{
    return (mouse.get_pos_x >= $left && mouse.get_pos_x < $right && mouse.get_pos_y >= $top && mouse.get_pos_y < $bottom)
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


command $read_controls
{
    property $d
    $input_active = system.check_active
    $direction = -1
    $action_confirm = 0
    $action_pause = 0
    $action_restart = 0
    $action_back = 0
    $action_exit = 0
    $action_mute = 0
    $pick_level = -1
    for ($d = 0, $d < 4, $d += 1)
    {
        $held[$d] = 0
    }
    if ($input_active == 0)
    {
        return
    }
    $held[0] = key[40].is_down || key['S'].is_down || joypad.key[1].is_down || joypad.key[17].is_down
    $held[1] = key[37].is_down || key['A'].is_down || joypad.key[2].is_down || joypad.key[18].is_down
    $held[2] = key[38].is_down || key['W'].is_down || joypad.key[0].is_down || joypad.key[16].is_down
    $held[3] = key[39].is_down || key['D'].is_down || joypad.key[3].is_down || joypad.key[19].is_down
    if (key[40].on_down || key['S'].on_down || joypad.key[1].on_down || joypad.key[17].on_down)
    {
        $preferred = 0
    }
    if (key[37].on_down || key['A'].on_down || joypad.key[2].on_down || joypad.key[18].on_down)
    {
        $preferred = 1
    }
    if (key[38].on_down || key['W'].on_down || joypad.key[0].on_down || joypad.key[16].on_down)
    {
        $preferred = 2
    }
    if (key[39].on_down || key['D'].on_down || joypad.key[3].on_down || joypad.key[19].on_down)
    {
        $preferred = 3
    }
    for ($d = 0, $d < 4, $d += 1)
    {
        if ($held[$d])
        {
            $direction = $d
        }
    }
    if ($held[$preferred])
    {
        $direction = $preferred
    }
    $action_confirm = key[13].on_down || key[32].on_down || joypad.key[4].on_down
    $action_pause = key['P'].on_down || key[27].on_down || mouse.right.on_down || joypad.key[12].on_down
    $action_restart = key['R'].on_down || joypad.key[6].on_down
    $action_back = key['Q'].on_down || joypad.key[5].on_down || joypad.key[13].on_down
    $action_exit = key['X'].on_down || key[27].on_down || joypad.key[5].on_down
    $action_mute = key['M'].on_down || joypad.key[7].on_down || (mouse.left.on_down && $in_box(994, 732, 1250, 776))
    if (($mode == 1 || $mode == 2) && mouse.left.on_down && $in_box(994, 678, 1250, 722))
    {
        $action_pause = 1
    }
    if ($mode == 0)
    {
        if (key[49].on_down || (mouse.left.on_down && $in_box(120, 512, 332, 576)))
        {
            $pick_level = 0
        }
        if (key[50].on_down || (mouse.left.on_down && $in_box(363, 512, 575, 576)))
        {
            $pick_level = 1
        }
        if (key[51].on_down || (mouse.left.on_down && $in_box(606, 512, 818, 576)))
        {
            $pick_level = 2
        }
        if (key[37].on_down || key['A'].on_down || joypad.key[2].on_down || joypad.key[18].on_down)
        {
            $pick_level = ($level + 2) % 3
        }
        if (key[39].on_down || key['D'].on_down || joypad.key[3].on_down || joypad.key[19].on_down)
        {
            $pick_level = ($level + 1) % 3
        }
        if (mouse.left.on_down && $in_box(290, 620, 650, 682))
        {
            $action_confirm = 1
        }
        if (mouse.left.on_down && $in_box(380, 710, 560, 748))
        {
            $action_exit = 1
        }
    }
    elseif ($mode == 2 || $mode == 3)
    {
        if (mouse.left.on_down && $in_box(310, 452, 630, 506))
        {
            $action_confirm = 1
        }
        if ($mode == 2 && mouse.left.on_down && $in_box(310, 522, 630, 566))
        {
            $action_restart = 1
        }
        if (mouse.left.on_down && $in_box(370, 590, 570, 630))
        {
            $action_back = 1
        }
    }
}

command $route_controls
{
    $request_start = 0
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
    elseif ($mode == 0)
    {
        if ($pick_level >= 0)
        {
            $level = $pick_level
        }
        if ($action_confirm)
        {
            $request_start = 1
        }
        elseif ($action_exit)
        {
            $request_exit = 1
        }
    }
    elseif ($mode == 1)
    {
        if ($action_pause || $action_restart)
        {
            $mode = 2
            $accumulator = 0
        }
    }
    elseif ($mode == 2)
    {
        if ($action_pause || $action_confirm)
        {
            $mode = 1
            $elapsed = 0
            $accumulator = 0
        }
        elseif ($action_restart)
        {
            $request_start = 1
        }
        elseif ($action_back)
        {
            $mode = 0
        }
    }
    elseif ($mode == 3)
    {
        if ($action_confirm || $action_restart)
        {
            $request_start = 1
        }
        elseif ($action_back || $action_pause)
        {
            $mode = 0
        }
    }
}


// Mixed growing-tree generation creates frequent forks without opening the border.
command $make_maze(property $size)
{
    property $i
    property $x
    property $y
    property $side
    property $head
    property $tail
    property $current
    property $top
    property $count
    property $d
    property $nx
    property $ny
    property $next
    property $pick
    property $best
    property $candidate
    property $active_index
    $level = math.limit(0, $size, 2)
    $width = 21
    $height = 15
    $tile = 44
    if ($level == 1)
    {
        $width = 27
        $height = 19
        $tile = 34
    }
    elseif ($level == 2)
    {
        $width = 31
        $height = 23
        $tile = 30
    }
    $cells = $width * $height
    $board_x = 24 + (930 - $width * $tile) / 2
    $board_y = 82 + (690 - $height * $tile) / 2
    $dx[0] = 0
    $dy[0] = 1
    $dx[1] = -1
    $dy[1] = 0
    $dx[2] = 0
    $dy[2] = -1
    $dx[3] = 1
    $dy[3] = 0
    for ($i = 0, $i < 713, $i += 1)
    {
        $grid[$i] = 1
        $seen[$i] = 0
        $visible[$i] = 0
        $last_seen[$i] = -12000
        $trail[$i] = 0
        $distance[$i] = -1
    }
    // Pick one non-corner boundary gate, and begin just inside that gate.
    $side = math.rand(0, 3)
    $entry_x = 1 + math.rand(0, ($width - 3) / 2) * 2
    $entry_y = 1 + math.rand(0, ($height - 3) / 2) * 2
    if ($side == 0)
    {
        $entry_y = 0
        $face = 0
    }
    elseif ($side == 1)
    {
        $entry_x = $width - 1
        $face = 1
    }
    elseif ($side == 2)
    {
        $entry_y = $height - 1
        $face = 2
    }
    else
    {
        $entry_x = 0
        $face = 3
    }
    $entry = $entry_y * $width + $entry_x
    $grid[$entry] = 0
    $x = $entry_x + $dx[$face]
    $y = $entry_y + $dy[$face]
    $current = $y * $width + $x
    $grid[$current] = 0
    $stack[0] = $current
    $top = 0
    while ($top >= 0)
    {
        $active_index = $top
        if (math.rand(0, 99) < 30)
        {
            $active_index = math.rand(0, $top)
        }
        $current = $stack[$active_index]
        $x = $current % $width
        $y = $current / $width
        $count = 0
        for ($d = 0, $d < 4, $d += 1)
        {
            $nx = $x + $dx[$d] * 2
            $ny = $y + $dy[$d] * 2
            if ($nx > 0 && $ny > 0 && $nx < $width - 1 && $ny < $height - 1)
            {
                $next = $ny * $width + $nx
                if ($grid[$next] == 1)
                {
                    $choices[$count] = $d
                    $count += 1
                }
            }
        }
        if ($count > 0)
        {
            $pick = $choices[math.rand(0, $count - 1)]
            $next = ($y + $dy[$pick] * 2) * $width + $x + $dx[$pick] * 2
            $grid[($y + $dy[$pick]) * $width + $x + $dx[$pick]] = 0
            $grid[$next] = 0
            $top += 1
            $stack[$top] = $next
        }
        else
        {
            $stack[$active_index] = $stack[$top]
            $top -= 1
        }
    }
    // Breadth-first distances choose a genuinely distant reachable exit.
    $queue[0] = $entry
    $distance[$entry] = 0
    $head = 0
    $tail = 1
    while ($head < $tail)
    {
        $current = $queue[$head]
        $head += 1
        $x = $current % $width
        $y = $current / $width
        for ($d = 0, $d < 4, $d += 1)
        {
            $nx = $x + $dx[$d]
            $ny = $y + $dy[$d]
            if ($nx >= 0 && $ny >= 0 && $nx < $width && $ny < $height)
            {
                $next = $ny * $width + $nx
                if ($grid[$next] == 0 && $distance[$next] < 0)
                {
                    $distance[$next] = $distance[$current] + 1
                    $queue[$tail] = $next
                    $tail += 1
                }
            }
        }
    }
    $best = -1
    $exit = -1
    for ($i = 0, $i < $cells, $i += 1)
    {
        $x = $i % $width
        $y = $i / $width
        $candidate = -1
        if ($y == 1 && $x % 2 == 1)
        {
            $candidate = $x
        }
        if ($y == $height - 2 && $x % 2 == 1)
        {
            $candidate = ($height - 1) * $width + $x
        }
        if ($x == 1 && $y % 2 == 1)
        {
            $candidate = $y * $width
        }
        if ($x == $width - 2 && $y % 2 == 1)
        {
            $candidate = $y * $width + $width - 1
        }
        if ($candidate >= 0 && $candidate != $entry && $distance[$i] > $best)
        {
            $exit = $candidate
            $best = $distance[$i]
        }
    }
    $grid[$exit] = 0
    $optimal_steps = $best + 1
    $exit_x = $exit % $width
    $exit_y = $exit / $width
    $player_x = $entry_x
    $player_y = $entry_y
    $to_x = $player_x
    $to_y = $player_y
    $walking = 0
    $walk_ms = 0
    $steps = 0
    $time_ms = 0
    $accumulator = 0
    $won = 0
    $floor_count = 0
    $explored = 0
    $fog_clock = 0
    $fog_update_ms = 0
    $map_dirty = 1
    $trail[$entry] = 1
    $sound = 0
    for ($i = 0, $i < $cells, $i += 1)
    {
        if ($grid[$i] == 0)
        {
            $floor_count += 1
        }
    }
    $reveal
}

// Ray-cast exploration with opaque walls and no diagonal corner peeking.
command $reveal
{
    property $tx
    property $ty
    property $x
    property $y
    property $ax
    property $ay
    property $sx
    property $sy
    property $err
    property $twice
    property $nx
    property $ny
    property $active
    property $i
    for ($i = 0, $i < $cells, $i += 1)
    {
        $visible[$i] = 0
    }
    for ($ty = $player_y - 4, $ty < $player_y + 5, $ty += 1)
    {
        for ($tx = $player_x - 4, $tx < $player_x + 5, $tx += 1)
        {
            if ($tx >= 0 && $ty >= 0 && $tx < $width && $ty < $height && ($tx - $player_x) * ($tx - $player_x) + ($ty - $player_y) * ($ty - $player_y) <= 20)
            {
                $x = $player_x
                $y = $player_y
                $ax = math.abs($tx - $x)
                $ay = math.abs($ty - $y)
                $sx = 1
                $sy = 1
                if ($tx < $x)
                {
                    $sx = -1
                }
                if ($ty < $y)
                {
                    $sy = -1
                }
                $err = $ax - $ay
                $active = 1
                while ($active == 1)
                {
                    $i = $y * $width + $x
                    $visible[$i] = 1
                    $last_seen[$i] = $time_ms
                    if ($seen[$i] == 0)
                    {
                        $seen[$i] = 1
                        if ($grid[$i] == 0)
                        {
                            $explored += 1
                        }
                    }
                    if (($x == $tx && $y == $ty) || $grid[$i] == 1)
                    {
                        $active = 0
                    }
                    else
                    {
                        $twice = $err * 2
                        $nx = $x
                        $ny = $y
                        if ($twice > -$ay)
                        {
                            $err -= $ay
                            $nx += $sx
                        }
                        if ($twice < $ax)
                        {
                            $err += $ax
                            $ny += $sy
                        }
                        if ($nx != $x && $ny != $y && ($grid[$y * $width + $nx] == 1 || $grid[$ny * $width + $x] == 1))
                        {
                            $active = 0
                        }
                        else
                        {
                            $x = $nx
                            $y = $ny
                        }
                    }
                }
            }
        }
    }
    $map_dirty = 1
}

// Current line of sight keeps refreshing memory. Elsewhere, fog returns in 12s.
command $refresh_fog
{
    property $i
    for ($i = 0, $i < $cells, $i += 1)
    {
        if ($visible[$i] == 1)
        {
            $last_seen[$i] = $time_ms
        }
        elseif ($seen[$i] == 1 && $time_ms - $last_seen[$i] >= 12000)
        {
            $seen[$i] = 0
            $trail[$i] = 0
            if ($grid[$i] == 0)
            {
                $explored -= 1
            }
        }
    }
    $map_dirty = 1
}

command $step_game(property $direction)
{
    property $nx
    property $ny
    property $next
    if ($won == 1)
    {
        return
    }
    $time_ms += 16
    $fog_clock += 16
    $fog_update_ms += 16
    if ($fog_update_ms >= 96)
    {
        $refresh_fog
        $fog_update_ms = 0
    }
    if ($walking == 1)
    {
        $walk_ms += 16
        if ($walk_ms >= 144)
        {
            $player_x = $to_x
            $player_y = $to_y
            $walking = 0
            $walk_ms = 0
            $steps += 1
            $next = $player_y * $width + $player_x
            $trail[$next] = 1
            $sound = 1
            $reveal
            if ($next == $exit)
            {
                $won = 1
                $sound = 3
            }
        }
    }
    elseif ($direction >= 0 && $direction < 4)
    {
        $face = $direction
        $nx = $player_x + $dx[$direction]
        $ny = $player_y + $dy[$direction]
        if ($nx >= 0 && $ny >= 0 && $nx < $width && $ny < $height)
        {
            $next = $ny * $width + $nx
            if ($grid[$next] == 0)
            {
                $to_x = $nx
                $to_y = $ny
                $walking = 1
                $walk_ms = 0
            }
        }
    }
}

command $advance(property $ms, property $direction)
{
    $accumulator += math.limit(0, $ms, 80)
    while ($accumulator >= 16 && $won == 0)
    {
        $step_game($direction)
        $accumulator -= 16
    }
}


command $create_stage
{
    property $i
    for ($i = 0, $i < 800, $i += 1)
    {
        front.object[$i].init
    }
    front.object[0].create("sm_background", 1, 0, 0)
    front.object[0].layer = 0
    for ($i = 1, $i < 5, $i += 1)
    {
        front.object[$i].create("sm_fog", 0, 0, 0)
        front.object[$i].layer = 5
        if ($i >= 3)
        {
            front.object[$i].patno = 1
            front.object[$i].layer = 12
            front.object[$i].tr = 140
        }
    }
    front.object[730].create("sm_locator", 0, 0, 0)
    front.object[730].layer = 15
    front.object[731].create("sm_hero", 0, 0, 0)
    front.object[731].layer = 20
    front.object[740].create("sm_portrait", 1, 1032, 102)
    front.object[740].layer = 100
    front.object[741].create("sm_status", 1, 994, 332)
    front.object[741].layer = 100
    front.object[742].create_number("sm_digits", 0, 998, 433)
    front.object[742].set_number_param(3, 1, 0, 0, 0, 0)
    front.object[742].layer = 101
    front.object[743].create_number("sm_digits_small", 0, 996, 531)
    front.object[743].set_number_param(4, 1, 0, 0, 0, 0)
    front.object[743].layer = 101
    front.object[744].create_number("sm_digits_small", 0, 1148, 531)
    front.object[744].set_number_param(2, 1, 0, 0, 0, 0)
    front.object[744].layer = 101
    front.object[745].create_number("sm_digits_small", 0, 1206, 531)
    front.object[745].set_number_param(2, 1, 0, 0, 0, 0)
    front.object[745].layer = 101
    front.object[746].create("sm_progress", 0, 1006, 487)
    front.object[746].layer = 101
    front.object[747].create_number("sm_digits_small", 1, 1170, 42)
    front.object[747].set_number_param(3, 1, 0, 0, 0, 0)
    front.object[747].layer = 101
    front.object[750].create("sm_btn_side", 0, 994, 678)
    front.object[750].layer = 105
    front.object[751].create("sm_sound", 1, 994, 732)
    front.object[751].layer = 105
    front.object[760].create("sm_title", 1, 0, 0)
    front.object[760].layer = 200
    front.object[761].create_rect(0, 0, 976, 800, 32, 48, 55, 160, 0)
    front.object[761].layer = 200
    front.object[762].create("sm_modal", 0, 230, 160)
    front.object[762].layer = 201
    front.object[763].create("sm_btn_title", 1, 290, 620)
    front.object[763].layer = 202
    front.object[764].create("sm_btn_main", 0, 310, 452)
    front.object[764].layer = 202
    front.object[765].create("sm_btn_restart", 0, 310, 522)
    front.object[765].layer = 202
    front.object[766].create("sm_btn_back", 0, 370, 590)
    front.object[766].layer = 202
    front.object[767].create("sm_btn_exit", 1, 380, 710)
    front.object[767].layer = 202
    for ($i = 0, $i < 3, $i += 1)
    {
        front.object[768 + $i].create("sm_level", 1, 120 + $i * 243, 512)
        front.object[768 + $i].layer = 202
    }
    bgm.play("sm_music", 1000)
}

command $create_map
{
    property $i
    for ($i = 1, $i < 5, $i += 1)
    {
        front.object[$i].disp = 1
        front.object[$i].set_clip(1, $board_x, $board_y, $board_x + $width * $tile, $board_y + $height * $tile)
    }
    for ($i = 0, $i < 713, $i += 1)
    {
        front.object[10 + $i].disp = 0
        $tile_pattern[$i] = -1
        if ($i < $cells)
        {
            if ($level == 0)
            {
                front.object[10 + $i].create("sm_tiles0", 1, 0, 0)
            }
            elseif ($level == 1)
            {
                front.object[10 + $i].create("sm_tiles1", 1, 0, 0)
            }
            else
            {
                front.object[10 + $i].create("sm_tiles2", 1, 0, 0)
            }
            front.object[10 + $i].set_pos($board_x + ($i % $width) * $tile, $board_y + ($i / $width) * $tile)
            front.object[10 + $i].layer = 10
        }
    }
    $map_visible = 1
    $map_dirty = 1
    $last_fog = -1
}

command $render_stage
{
    property $i
    property $x
    property $y
    property $mask
    property $pattern
    property $fog
    property $px
    property $py
    property $walk
    property $drift
    property $age
    property $opacity
    if ($mode == 0)
    {
        if ($map_visible == 1)
        {
            for ($i = 0, $i < $cells, $i += 1)
            {
                front.object[10 + $i].disp = 0
            }
            $map_visible = 0
        }
        for ($i = 1, $i < 5, $i += 1)
        {
            front.object[$i].disp = 0
        }
        front.object[730].disp = 0
        front.object[731].disp = 0
        return
    }
    // Two continuous, counter-drifting cloud layers fill the maze viewport.
    $drift = ($fog_clock / 75) % 1024
    front.object[1].set_pos($board_x - $drift, $board_y - 38)
    front.object[2].set_pos($board_x - $drift + 1024, $board_y - 38)
    $drift = ($fog_clock / 48) % 1024
    front.object[3].set_pos($board_x + $drift - 1024, $board_y - 38)
    front.object[4].set_pos($board_x + $drift, $board_y - 38)
    $fog = $fog_clock / 96
    if ($map_dirty == 1 || $last_fog != $fog)
    {
        for ($i = 0, $i < $cells, $i += 1)
        {
            $x = $i % $width
            $y = $i / $width
            $pattern = 0
            front.object[10 + $i].disp = $seen[$i]
            if ($seen[$i] == 1)
            {
                $age = $time_ms - $last_seen[$i]
                $opacity = 255
                if ($age > 8000)
                {
                    $opacity = math.limit(0, (12000 - $age) * 255 / 4000, 255)
                }
                front.object[10 + $i].tr = $opacity
                $pattern = ($x + $y) % 2
                if ($trail[$i] == 1)
                {
                    $pattern = 2
                }
                if ($grid[$i] == 1)
                {
                    $mask = 0
                    if ($y > 0)
                    {
                        if ($seen[$i - $width] == 1 && $grid[$i - $width] == 1)
                        {
                            $mask += 1
                        }
                    }
                    if ($x < $width - 1)
                    {
                        if ($seen[$i + 1] == 1 && $grid[$i + 1] == 1)
                        {
                            $mask += 2
                        }
                    }
                    if ($y < $height - 1)
                    {
                        if ($seen[$i + $width] == 1 && $grid[$i + $width] == 1)
                        {
                            $mask += 4
                        }
                    }
                    if ($x > 0)
                    {
                        if ($seen[$i - 1] == 1 && $grid[$i - 1] == 1)
                        {
                            $mask += 8
                        }
                    }
                    $pattern = 5 + $mask
                }
                if ($i == $entry)
                {
                    $pattern = 3
                }
                if ($i == $exit)
                {
                    $pattern = 4
                }
            }
            if ($tile_pattern[$i] != $pattern)
            {
                front.object[10 + $i].patno = $pattern
                $tile_pattern[$i] = $pattern
            }
        }
        $map_dirty = 0
        $last_fog = $fog
    }
    $px = $board_x + $player_x * $tile + $tile / 2
    $py = $board_y + $player_y * $tile + $tile / 2
    $walk = 0
    if ($walking == 1)
    {
        $px += ($to_x - $player_x) * $tile * $walk_ms / 144
        $py += ($to_y - $player_y) * $tile * $walk_ms / 144
        $walk = ($steps + $walk_ms / 72) % 2
    }
    front.object[730].disp = 1
    front.object[730].set_pos($px - 22, $py - 11)
    front.object[731].disp = 1
    front.object[731].set_pos($px - 28, $py - 50)
    front.object[731].patno = $face + $walk * 4
}

command $render_ui
{
    property $i
    property $percent
    property $show
    property $hover
    $show = $mode != 0
    $percent = 0
    if ($floor_count > 0)
    {
        $percent = $explored * 100 / $floor_count
    }
    front.object[741].patno = $level * 4 + $mode
    front.object[742].disp = 1
    front.object[742].set_number($percent * $show)
    front.object[743].disp = 1
    front.object[743].set_number(math.min($steps, 9999) * $show)
    front.object[744].disp = 1
    front.object[744].set_number(math.min($time_ms / 60000, 99) * $show)
    front.object[745].disp = 1
    front.object[745].set_number((($time_ms / 1000) % 60) * $show)
    front.object[746].disp = $show
    front.object[746].scale_x = $percent * 10
    front.object[747].set_number(math.min(G[0], 999))
    front.object[750].disp = ($mode == 1 || $mode == 2)
    front.object[750].patno = ($mode == 2) * 2 + $in_box(994, 678, 1250, 722)
    front.object[751].patno = $muted * 2 + $in_box(994, 732, 1250, 776)
    front.object[760].disp = ($mode == 0)
    front.object[761].disp = ($mode == 2 || $mode == 3)
    front.object[762].disp = ($mode == 2 || $mode == 3)
    front.object[762].patno = ($mode == 3)
    front.object[763].disp = ($mode == 0)
    front.object[763].patno = $in_box(290, 620, 650, 682)
    front.object[764].disp = ($mode == 2 || $mode == 3)
    front.object[764].patno = ($mode == 3) * 2 + $in_box(310, 452, 630, 506)
    front.object[765].disp = ($mode == 2)
    front.object[765].patno = $in_box(310, 522, 630, 566)
    front.object[766].disp = ($mode == 2 || $mode == 3)
    front.object[766].patno = $in_box(370, 590, 570, 630)
    front.object[767].disp = ($mode == 0)
    front.object[767].patno = $in_box(380, 710, 560, 748)
    for ($i = 0, $i < 3, $i += 1)
    {
        $hover = $in_box(120 + $i * 243, 512, 332 + $i * 243, 576)
        if ($i == $level)
        {
            $hover = 2
        }
        front.object[768 + $i].disp = ($mode == 0)
        front.object[768 + $i].patno = $i * 3 + $hover
    }
}
