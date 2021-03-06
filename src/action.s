// unit controlling related stuff
use action_

Acts = t

dact idle.start
| U = $unit
| when U.anim >< move: U.animate{idle}

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

// Following movement code handles movement between cells
move_start Me =
| U = $unit
| when $xyz><U.xyz:
  | U.set{toXYZ U.fxyz}
  | $cycles <= 0
  | leave
| X,Y,Z = $xyz - U.xyz
| U.set{fromXYZ U.fxyz}
| U.move{$xyz}
| U.set{toXYZ U.fxyz}
| U.fxyz.init{U.get{fromXYZ}}
| U.facing <= Dirs.locate{X,Y}
| when U.anim<>move: U.animate{move}
| $cycles <= U.speed
| when X >< -Y: $cycles <= max 1 $cycles*3/2
| U.set{startCycles $cycles}
| when got@@it U.class.onMove: U.effect{it U U.xyz}

move_update Me =
| U = $unit
| FromXYZ = U.get{fromXYZ}
| V = U.get{toXYZ} - FromXYZ
| StartCycles = U.get{startCycles}
| U.fxyz.init{FromXYZ + V*(StartCycles-$cycles)/StartCycles}

move_finish Me =
| U = $unit
| U.fxyz.init{U.get{toXYZ}}
| U.on_entry
| U.strip{startCycles}
| U.strip{fromXYZ}
| U.strip{toXYZ}


dact move.valid
| U = $unit
| U.world.no_block_at{$xyz} and U.can_move{}{U U.cell $xyz.cell}

dact move.start
| move_start Me

dact move.update | move_update Me
dact move.finish | move_finish Me


dact missile.start
| U = $unit
| U.set{fromXYZ U.fxyz}
| U.move{$xyz}
| U.set{toXYZ U.fxyz}
| U.fxyz.init{U.get{fromXYZ}}
| less $cycles: $cycles <= 1
| U.set{startCycles $cycles}

dact missile.update
| U = $unit
| FromXYZ = U.get{fromXYZ}
| V = U.get{toXYZ} - FromXYZ
| StartCycles = U.get{startCycles}
| U.fxyz.init{FromXYZ + V*(StartCycles-$cycles)/StartCycles}

dact missile.finish
| U = $unit
| _,UId,USerial,Es = U.get{missile}.0
| Source = U.world.units.UId
| less Source.serial >< USerial: Source <= $world.nil
| Source.effect{Es $target $xyz}
| U.free

dact die.start
| U = $unit
| U.drop_all
| less U.anim><death: U.animate{death}
| less not (U.class.hp-U.hp)>0 or got U.sprite.anims.death:
  | U.free
  | $cycles <= 1000

dact die.finish
| U = $unit
| when U.leader and U.hp << 0: U.owner.lost_leader{U}
| U.free

dact swap.valid
| T = $target
| less $target and not $target.removed: leave 0
| U = $unit
| U.owner.id >< T.owner.id and T.idle

dact swap.start
| U = $unit
| move_start Me
| T = $target
| O = T.order
| less T.path.end: T.set_path{[T.cell @T.path.list]}
| O.init{move U.from}
| O.priority <= 100

dact swap.update | move_update Me

dact swap.finish | move_finish Me


dact ascend.start | when $unit.anim<>move: $unit.animate{move}

ascend_update Me GoalZ =
| FDst = $fxyz+[0 0 $ascendSpeed]
| when FDst.2 < (GoalZ*$world.c)
  | $fine_move{FDst}
  | leave 1
| $move{[$xyz.0 $xyz.1 GoalZ]}
| 0
dact ascend.update | $cycles <= ascend_update $unit $xyz.2

dact fastmove.start
| $unit.move{$xyz}
| $unit.on_entry

custom_init Me =
custom_valid Me =
| invalid Error =
  | $unit.owner.notify{Error}
  | $unit.main.sound{illegal}
| $act.validate{$unit $xyz $target &invalid}


custom_start Me =
| U = $unit
| when got@@it $act.animate: U.animate{it}
| U.face{$xyz}
| when $onInit: U.effect{$onInit $target $xyz}
custom_update Me =
custom_finish Me =
| U = $unit
| when $onEnd: U.effect{$onEnd $target $xyz}


default_init Me =
default_valid Me = 1
default_start Me =
default_update Me =
default_finish Me =

for Name,Act Acts
| have Act.init &default_init
| have Act.valid &default_valid
| have Act.start &default_start
| have Act.update &default_update
| have Act.finish &default_finish

type action{unit}
   type
   act
   cycles // cooldown cycles remaining till the action safe-to-change state
   priority
   xyz/[0 0 0] // target x,y,z
   target // when action targets a unit
   range
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

world.action Unit = action Unit

action.main = $unit.main

action.cost =
| Cost = $act.cost
| when $target and $act.check.will: Cost += $target.class.will
| Cost
action.check = $act.check
action.onInit = $act.onInit
action.onHit =
| less $act: leave //in case it is just an animation
| OnHit = $act.onHit
| when got OnHit:
  | Target = $target
  | if Target then $unit.effect{OnHit Target Target.xyz}
    else $unit.effect{OnHit 0 $xyz}

action.onEnd = $act.onEnd

action.as_text = "#action{[$type] [$priority] [$target]}"
action.init Act Target =
| $type <= if Act.is_text then Act else Act.name
| XYZ = if Target.is_list then Target
        else if Target then Target.xyz
        else $unit.xyz
| $xyz.init{XYZ}
| $target <= if Target.is_list then 0 else Target
| A = Acts.$type
| $act <= if Act.is_text then $main.params.acts.$type else Act
| less got $act: bad "unknown action type [$type]"
| $range <= $act.range
| $cycles <= $act.speed
| $priority <= $act.priority
| if got A then
    | $act_init <= A.init
    | $act_valid <= A.valid
    | $act_start <= A.start
    | $act_update <= A.update
    | $act_finish <= A.finish
  else
    | $act_init <= &custom_init
    | $act_valid <= &custom_valid
    | $act_start <= &custom_start
    | $act_update <= &custom_update
    | $act_finish <= &custom_finish
| $act_init{}{Me}
| Me

action.valid =
| $act_valid{}{Me}

action.start =
| $act_start{}{Me}

action.update =
| $act_update{}{Me}
| $cycles--

action.finish =
| $act_finish{}{Me}
