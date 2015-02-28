// game world update routines

main.update =
| $world.update

world.init_game =
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn // hack to begin turns from 1

world.end_turn =
| NextPlayer = $player.id+1
| less NextPlayer < $players.size
  | NextPlayer <= 0
  | !$turn + 1
| P = $players.NextPlayer
| $player <= P
| P.power <= 1
| P.pentagram <= 0
| PID = P.id
| for U $units.keep{U => not U.removed and U.owner.id >< PID}
  | when U.type >< special_pentagram: P.pentagram <= U
  | when U.level: for V $units_at{U.xyz}
    | when V.type >< special_node
      | !P.power+1
| P.moves <= $player.power
| $on_player_change P

world.update =
| NextActive = []
| while $active.used
  | U = $active.pop
  | U.update
  | when U.active: push U NextActive
| for U NextActive: $active.push{U}
| !$cycle + 1

unit.update =
| when $removed
  | $active <= 0
  | leave
| !$anim_wait - 1
| less $anim_wait > 0
  | $anim_step <= ($anim_step+1)%$anim_seq.size
  | $pick_facing{$facing}
  | $anim_wait <= $anim_seq.$anim_step.1
| when $ordered.class
  | when $ordered.valid and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | $ordered.class <= 0
| till $action.cycles > 0 // action is done?
  | when $anim<>idle and $anim<>move and
         ($anim_step <> $anim_seq.size-1 or $anim_wait > 1):
    | leave 1
  | $action.finish
  | less $anim >< idle: $animate{idle}
  | if     $next_action.valid
       and $level << $world.player.moves
       and $moved <> $world.turn
    then | !$world.player.moves - $next_action.cost
         | $moved <= $world.turn
    else $next_action.init{idle $xyz}
  | swap $action $next_action
  | $next_action.class <= 0
  | $next_action.priority <= 0
  | $action.start
| $action.update
| 1