// unit controlling related stuff

type act_class

act_class.init A =
act_class.valid A = 1
act_class.start A = A.cycles <= A.unit.sprite.speed
act_class.update A =
act_class.finish A =

type act_idle.act_class class_name/idle anim/idle

act_idle.start A =  when A.cycles >< -1: A.cycles <= 4

type act_move.act_class class_name/move anim/move

act_move.valid A =
| U = A.unit
| U.world.no_block_at{A.xyz} and U.can_move{U.xyz A.xyz}

// dirs requiring dummy to avoid overlapping unit with tiles
OverlapDirs = list [-1  1] [-1  0] [-1 -1] [ 0 -1]

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

move_start A =
| U = A.unit
| X,Y,Z = A.xyz - U.xyz
| U.movement_render_hack <= got OverlapDirs.locate{X,Y}
| A.fromXY.init{U.xy}
| A.fromXYZ.init{U.xyz}
| U.move{A.xyz}
| U.facing <= Dirs.locate{X,Y}
| U.animate{move}
| A.start_cycles <= A.cycles
| when got!it U.sounds.move: U.main.sound{it.rand}

move_update A =
| U = A.unit
| X,Y,Z = A.fromXYZ-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
| when not (X and Y)
  | !XUnit/2
  | !YUnit/2
| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| U.xy.init{A.fromXY + [X*XUnit Y*YUnit]*A.cycles/A.start_cycles}

move_finish A =
| U = A.unit
| U.xy.init{A.fromXY}
| U.movement_render_hack <= 0

act_move.start A =
| U = A.unit
| when A.cycles >< -1: A.cycles <=  U.sprite.speed
| move_start A
| X,Y,Z = U.xyz
| less U.seen
  | A.cycles <= 0
  | move_finish A

act_move.update A = move_update A

act_move.finish A = move_finish A

type act_attack.act_class class_name/attack anim/attack

act_attack.valid A =
| T = A.target
| when T.is_list or T.removed or T.empty or not T.health: leave 0
| U = A.unit
//| when U.skirmisher: leave (T.xyz - U.xyz).all{?.abs<<1}
| if U.ranged then 1 else U.can_move{U.xyz T.xyz}

act_attack.init A =
| A.data <= 0

act_attack.start A =
| U = A.unit
| U.face{A.target.xyz}
| A.cycles <= max 1 U.sprite.anim_speed{attack}
| U.animate{attack}
| when got!it U.sounds.attack: U.main.sound{it.rand}

act_attack.update A =
| U = A.unit
| when A.cycles > 9000 // if target is dying, wait till it is dead
  | when U.world.waiting: leave
  | A.target <= 0
  | when A.unit.ranged:
    | A.cycles <= 1
    | leave
  | less A.unit.ranged: 
    | A.cycles <= max 1 U.sprite.speed/2
    | move_start A
  | leave
| when A.data > 0: move_update A
| when A.cycles >< 1 and A.data < 2:
  | when A.data >< 1:
    | leave
    | less A.unit.ranged: leave
    | move_finish A
    | A.xyz.init{A.fromXYZ}
    | A.cycles <= max 1 A.unit.sprite.speed*2/3
    | move_start A
    | A.data <= 2
  | when A.data >< 0:
    | Target = A.target
    | U.world.effect{Target.xyz blood}
    | Damage = max 0 U.attack-Target.defense
    | when Target.harm{U Damage}
    | U.animate{idle}
    | when Target.hits < Target.health:
      | A.data <= 2
      | A.cycles <= 0
      | leave
    | A.data <= 1
    | A.cycles <= 90000

act_attack.finish A =
| move_finish A


type act_die.act_class class_name/die anim/action

act_die.valid A = 1

free_unit U = 
| when U.id >< U.world.waiting: U.world.waiting <= 0
| U.free

act_die.start A =
| U = A.unit
| U.animate{death}
| less not U.hits or got U.sprite.anims.death:
  | free_unit U
  | A.cycles <= 1000

act_die.finish A =
| free_unit A.unit

type act_swap.act_class class_name/swap anim/action

act_swap.valid A =
| T = A.target
| less A.target and not A.target.removed: leave 0
| U = A.unit
| Turn = U.world.turn
| U.owner.id >< T.owner.id and U.moved < Turn and T.moved < Turn

act_swap.start A =
| U = A.unit
| A.cycles <= max 1 U.sprite.speed
| move_start A
| !A.target.owner.moves + 2
| A.target.order.init{act/move at/A.fromXYZ}

act_swap.update A =
| move_update A

act_swap.finish A =
| move_finish A
| !A.target.owner.moves - 1



type act_pentagram.act_class class_name/pentagram anim/action

act_pentagram.valid A =
| T = A.unit
| T.world.units_at{T.xyz}.all{?.empty >< 0}

act_pentagram.start A =
| A.unit.animate{attack}
| A.unit.main.sound{pentagram}

act_pentagram.finish A =
| U = A.unit
| Pentagram = U.owner.pentagram
| when not Pentagram
  | Pentagram <= U.world.alloc_unit{A.effect}
  | Pentagram.owner <= U.owner
  | U.owner.pentagram <= Pentagram
| Pentagram.move{A.xyz}


type act_summon.act_class class_name/summon anim/action

act_summon.valid A =
| T = A.target
| less A.target and not A.target.removed: leave 0
| T.world.units_at{T.xyz}.all{?empty}

act_summon.start A =
| U = A.unit
| U.animate{attack}
| U.main.sound{summon}
| Leader = U.owner.leader
| when Leader
  | Leader.animate{attack}
  | Leader.face{U.xyz}
| U.world.effect{A.target.xyz teleport}

act_summon.finish A =
| S = A.unit.world.alloc_unit{A.effect}
| S.owner <= A.unit.owner
| S.attacker <= 1 // mark it available for attack
| S.move{A.target.xyz}
| S.world.update_pick{[S]}


type act_spell_of_mastery.act_class class_name/summon anim/action

act_spell_of_mastery.start A =
| U = A.unit
| U.animate{attack}
| U.main.sound{summon}
| U.world.effect{U.xyz teleport}

act_spell_of_mastery.finish A =
| U = A.unit
| U.world.params.winner <= U.owner.id
| U.world.params.victory_type <= 'Victory by casting the Spell of Mastery'



ActionClasses = t idle(act_idle) move(act_move) attack(act_attack) die(act_die)
                  swap(act_swap)
                  pentagram(act_pentagram) 
                  spell_of_mastery(act_spell_of_mastery)
                  summon(act_summon)

type action{unit}
   class
   target // when action targets a unit
   xyz/[0 0 0] // target x,y,z
   cycles // cooldown cycles remaining till the action safe-to-change state
   start_cycles
   priority // used to check if action can be preempted
   fromXYZ/[0 0 0]
   fromXY/[0 0]
   speed
   data // data used by class
   cost
   effect
   path

action.as_text = "#action{[$class_name] [$priority] [$target]}"

action.init act/idle at/self target/0 cost/0 effect/0 path/0 speed/-1 =
| when Target >< self: Target <= $unit
| when Target >< pentagram: Target <= $unit.owner.pentagram
| when Target: At <= Target.xyz
| $xyz.init{At}
| $target <= Target
| $priority <= 50
| $class <= ActionClasses.Act
| $cycles <= -1
| $cost <= Cost
| $speed <= Speed
| $effect <= Effect
| $path <= Path
| less got $class: bad "unknown action class [Act]"
| $class.init{Me}
| Me

action.class_name = $class and $class.class_name

action.valid = $class and $class.valid{Me}

action.start =
| $class.start{Me}

action.update =
| $class.update{Me}
| !$cycles - 1

action.finish =
| $class.finish{Me}
| when $path: $path^uncons{path}{?free}

export action