use util effect_ macros

Effects = t


effect on When: No

effect add @Args:
| Name = 0
| Duration = 0
| case Args
  [N] | Name <= N
  [N D] | Name <= N
        | Duration <= D
  Else | bad 'effect add: wrong number of arguments: [Args]'
| Target.add_gene{Name Duration []}

effect strip Name:
| when got Target.class.inborn.find{Name}: leave
| Target.strip{Name}

effect add_item Name Amount: Target.add_item{Name Amount}

effect tenant_mark Type:
| Block = $world.block_at{TargetXYZ}
| S = $world.units_get{TargetXYZ}.find{?type><Type}
| less Block:
  | when got S:
    | S.delta <= 50
    | when S.alpha><255
      | S.die
  | leave
| when got S: leave
| S = $owner.alloc_unit{Type}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}

effect turn State Players ActNames:
| when Players >< owner: Players <= [$owner.id] 
| when Players >< target_owner: Players <= [Target.owner.id]
| $world.turn_act{State Players ActNames}

effect gain @Args:
| ActNames = []
| Player = 0
| case Args
   [ANs] | ActNames <= ANs
         | Player = Target.owner
   [PId ANs] | ActNames <= ANs
             | Player <= $world.players.PId
| when ActNames >< all: ActNames <= $main.params.acts{}{?0}
| for ActName ActNames:
  | when ActNames.size><1 and Target.owner.human:
    | Title = ActName.replace{'_' ' '}
    | Player.notify{"Gained knowledge of [Title]."}
  | $world.turn_act{1 Player.id ActName}
  | Player.research_item{ActName}

effect cool Time: $add_gene{cool Time [$action.type $world.turn Time]}

effect explore Player State: $world.explore{State}

effect confirm Title Text:
| $main.show_message{Title buttons/[yes,'Yes' no,'No'] Text}

effect animate Anim: $animate{Anim}

effect macro Name:
| M = $main.params.macro.Name
| when no M: bad "main/macro.txt doesnt define `[Name]`"
| $effect{M Target TargetXYZ}

effect visual Effect:
| E = $world.visual{TargetXYZ Effect}
| when Target: E.fxyz.init{Target.fxyz}

effect visual1 Effect: //this one guards against multiple instances
| Type = "effect_[Effect]"
| E = $world.units_get{TargetXYZ}.find{?type><Type}
| when got E: leave
| $world.visual{TargetXYZ Effect}

effect sound Sound: $sound{Sound}

effect heal Amount: Target.harm{Me -Amount}

effect harm Damage: Target.harm{Me Damage}

effect hit Damage: $hit{Damage Target}

effect punish MaxDamage:
| Damage = if Target.kills>>1 then Target.hp else Target.sinned
| Target.harm{Me min{MaxDamage Damage}}

effect lifedrain Amount:
| when Amount >< full: Amount <= $class.hp
| Amount <= min{Amount Target.hp $class.hp-$hp}
| Target.harm{Me Amount}
| $harm{Me -Amount}

effect shake_screen Cycles: $world.shake{Cycles}
effect color_overlay @List: $world.set_color_overlay{List}

effect area As: //area{any,3,harm{magic.2}}
| [Whom Range @Es] = As
| Ts = $world.units_in_range{TargetXYZ Range}.skip{?empty}
| case Whom [exclude_self W]:
  | Whom <= W
  | Ts <= Ts.skip{?id><$id}
| when Whom><ally: Ts <= Ts.skip{?is_enemy{Me}}
| when Whom><enemy: Ts <= Ts.keep{?is_enemy{Me}}
| for T Ts: $effect{Es T T.xyz}

effect detonate Args:
| B = $world.block_at{TargetXYZ}
| Damage = Target.class.hp
| Target.harm{Me Damage}
| for D Dirs43
  | B = $world.block_at{TargetXYZ+D}
  | when B: B.harm{Me Damage}

effect explosion Range:
| for U $world.units_in_range{TargetXYZ Range}
  | Damage = max 1 Range-TargetXYZ.mdist{U.xyz}
  | U.harm{Me Damage}

effect notify Text: Target.owner.notify{Text}

effect msg Title @Body: $main.show_message{Title Body.text{' '}}

effect mana Amount: Target.owner.mana+=Amount

type unit_getset{unit}

unit_getset.`.` K =
| Getter = $unit.main.params.unit_getters_.K
| when no Getter: bad "unit_getset: unknown unit field [K]"
| Getter $unit

unit_getset.`=` K V =
| Setter = $unit.main.params.unit_setters_.K
| when no Setter: bad "unit_getset: unknown unit field [K]"
| Setter $unit V

effect set Name Value: unit_getset{Target}.Name <= Value

effect inc Name Value: unit_getset{Target}.Name += Value

effect world_set Name Value: $world.params.Name <= Value

effect boost_defense Amount: $def <= min{$def+Amount $class.def+Amount}

effect spell_of_mastery:
| $world.params.winner <= $owner.id
| $world.params.victory_type <= 'Victory by casting the Spell of Mastery'


effect swap Arg:
| XYZ = $xyz.copy
| Target.remove
| $move{TargetXYZ}
| Target.move{XYZ}

effect recall:
| P = $owner.pentagram
| when P.removed: leave
| Target.remove
| Target.move{P.xyz}
| Target.backtrack <= 0
| Target.reset_goal
| Target.reset_followers

effect gateway:
| B = $cell.block
| less B: leave
| T = $cell.gate
| less T: leave
| $world.visual{B.xyz teleport}
| A = T.cell.block
| B.move{T.xyz}
| B.reset_goal
| when A:
  | AH = A.health
  | BH = B.health
  | B.harm{0 AH}
  | A.harm{0 BH}
| $world.visual{T.xyz teleport}
| $sound{summon}

effect interrupt: Target.interrupt

effect remove: Target.free

effect die Whom:
| T = if Whom >< self then Me else Target
| when T.action.type <> die: T.die

effect clear Where:
| X,Y,Z = case Where
  target | TargetXYZ
  X,Y,Z | X,Y,Z
  Else | bad "effect clear: invalid target ([Where])"
| $world.clear_tile{X Y Z}

effect set_tile [X Y Z] Type:
| Tile = $main.tiles.Type
| when no Tile:
  | say "set_tile: missing tile `[Type]`"
  | leave
| $world.set{X Y Z Tile}

effect spawn What:
| when What><auto: What <= "unit[$action.act.name.drop{6}]"
| S = $owner.alloc_unit{What}
| S.aistate <= \spawned
| less S.alpha:
  | S.alpha <= 255
  | S.delta <= -50
| S.move{TargetXYZ}

effect spawn_item ItemType Amount: $cell.add_item{ItemType Amount}

effect drop ItemType Amount:
| when ItemType><_: ItemType <= $action.type.drop{5}
| MaxAmount = $get_item{ItemType}
| when Amount><all: Amount <= MaxAmount
| Amount <= min{MaxAmount Amount}
| $drop_item{ItemType Amount}

effect take ItemType Amount:
| when ItemType><_: ItemType <= $action.type.drop{5}
| MaxAmount = $cell.get_item{ItemType}
| when Amount><all: Amount <= MaxAmount
| Amount <= min{MaxAmount Amount}
| $add_item{ItemType Amount}
| $cell.add_item{ItemType -Amount}

effect morph ClassName:
| Class = $main.classes.ClassName
| less got Class: bad "morph: Missing class `[ClassName]`"
| $morph{Class}

effect charm NewOwner:
| when Target.will<0:
  | $owner.notify{"Can't subvert this unit."}
  | leave
| when $owner.mana < Target.will:
  | $owner.notify{"Not enough mana to subvert this unit."}
  | leave
| $owner.mana -= Target.will
| XYZ = Target.xyz.deep_copy
| Target.remove
| Target.owner <= $owner
| Target.colors <= $owner.colors
| Target.move{XYZ}

effect child ChildType Genes:
| S = $owner.alloc_unit{ChildType}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}
| S.host <= Target
| S.host_serial <= Target.serial
| S.add_genes{Genes}

effect caster Who:
| Leader = $owner.leader
| less Who >< leader and Leader: leave
| Leader.animate{attack}
| Leader.face{TargetXYZ}

knockback Me Target =
| Dir = Target.xyz-$xyz
| less Dir.all{?abs<<1}: leave
| Dir.2 <= 0
| DXYZ = Target.xyz+Dir
| DC = $world.cell{@DXYZ}
| when DC.tile.empty and not DC.block: Target.move{DXYZ}

effect blowaway R BlowSelf:
| Handled = []
| for DX,DY points_in_diamond{R}:
  | B = $world.block_at_safe{TargetXYZ+[DX DY 0]}
  | when B and not Handled.has{B.id} and (BlowSelf or B.xyz<>TargetXYZ):
    | push B.id Handled
    | N = max 0 R-(DX.abs+DY.abs)
    | BP = B.xyz
    | when TargetXYZ >< BP:
      | DX <= B.direction.0
      | DY <= B.direction.1
    | D = if DX.abs>DY.abs then [DX.sign 0 0] else [0 DY.sign 0]
    | TP = BP
    | Trail = []
    | times I N:
      | T = BP + D*(I+1)
      | less $world.valid{@T}: done
      | F = $world.cellp{T}.floor
      | less F.vacant: done
      | Prev = TP
      | TP <= T
      | push T Trail
      | less B.flyer:
        | when (F-1).tile.liquid: done //ensure water blocks non-flyers
        | when Prev.2 - F.xyz.2 >> 2: done //cliff stops movement
    | when TP<>BP:
      | B.reset_goal
      | B.move{TP}
      | for T Trail:
        | less got $world.units_get{T}.find{?type><effect_dustend}:
          | $world.visual{T dustend}
    | $world.visual{B.xyz dust}

effect jumpdown:
| $reset_goal
| $animate{idle}
| $forced_order{move [@TargetXYZ.take{2} $xyz.2]}

effect teleport Arg:
| $reset_goal
| $forced_order{fastmove TargetXYZ}

effect upkeep Amount:
| $owner.mana -= Amount

effect lore Amount:
| Target.owner.lore += Amount

effect victory Player Reason:
| WP = $world.params
| when Player >< owner: Player <= $owner.id
| WP.winner <= Player
| WP.victory_type <= Reason

effect face:
| $face{TargetXYZ}

effect align How:
| less How><door: bad "effect align: cant [How]-align"
| X,Y,Z = $xyz
| less $world.at{X Y-1 Z}.empty or $world.at{X Y+1 Z}.empty:
  | $face{$xyz+[1 0 0]}
  | T = $world.at{X Y-1 Z}
  | when T.wallShift and not $world.at{X+1 Y Z}.type><T.around:
    | $fxyz.init{$fxyz+[T.wallShift 0 0]}
  | leave
| $face{$xyz+[0 1 0]}
| T = $world.at{X-1 Y Z}
| when T.wallShift and not $world.at{X Y+1 Z}.type><T.around:
  | $fxyz.init{$fxyz+[0 T.wallShift 0]}

unit.yes_research ActName =
| Act = $main.params.acts.ActName
| Needs = $owner.lore-Act.lore
| when Needs < 0:
  | $owner.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| $owner.lore -= Act.lore
| $owner.research_item{ActName}
| $sound{gong}
| leave

effect yes
| MenuActName,XYZ,TargetSerial = $get{menuact}
| T = 0
| when got TargetSerial:
  | when TargetSerial><research:
    | $yes_research{MenuActName}
    | leave
  | T <= $active.list.find{?serial><TargetSerial}
  | when no T or not T.alive:
    | $owner.notify{"Target is lost!"}
    | leave
| Act = $main.params.acts.MenuActName
| when no Act:
  | $owner.notify{"effect yes: missing act [MenuActName]"}
  | leave
| $order_at{(T or XYZ) Act}

effect no | No

check_when Me Target C =
| leave: case C
  ally | not $owner.is_enemy{Target.owner}
  enemy | $owner.is_enemy{Target.owner}
  confirmed | $main.dialog_result><yes
  harmed | Target.health<>Target.class.hp
  idle | not Target.goal
  rested | $mov><$class.mov
  resting | Target.resting
  [`+` not C] | not: check_when Me Target C
  [`.` below Type] | (Target.cell-1).type><Type
  [`.` has_health A] | Target.health>>A
  [`.` has_mana A] | $owner.mana>>A
  [`.` has Effect] | Target.has{Effect}
  [`.` hasnt Effect] | not Target.has{Effect}
  [`.` got_child Type] | got Target.child{Type}
  [`.` no_child Type] | no Target.child{Type}
  Else | 0

unit.effect Effect Target TargetXYZ =
| XYZ = Target.xyz.deep_copy
| when XYZ.2 >< -1: leave
| case Effect [on,When @Es]: Effect <= Es
| T = Target
| Es = Effect.list
| RunActEffects = 1
| when Es.size >< 0 or (T.is_unit and T.id><$id):
  | RunActEffects <= 0 // action doesnt affect outside world
| till Es.end
  | E = pop Es
  | less E.is_list: E <= [E []]
  | Name,@Args = E
  | F = Effects.Name
  | if got F then F{Me T XYZ Args}
    else if Name >< when then
      | When = Args
      | Cs = if When.is_list and not When.end and When.0<>`.` and When.0<>`+`
             then When
             else [When]
      | less Cs.all{C => check_when Me T C}:
        | while not Es.end and Es.0<>endwhen: pop Es
    else if Name >< endwhen then
    else if Name >< resist then
      | when T.resisting:
        | $world.visual{T.xyz resist}
        | T.sound{resist}
        | less got T.class.inborn.find{resist}: T.strip{resist}
        | leave
    else if Name >< shell then
      | less $assault{Target}: leave
      | when T.shelled:
        | $world.visual{T.xyz shell}
        | T.sound{shell}
        | less got T.class.inborn.find{shell}: T.strip{shell}
        | leave
      | when $range<<1: Target.run_genes{counter target/Me xyz/Me.xyz}
      | when T.cursed: less $blessed or $cursed:
        | $owner.notify{"Can't harm cursed unit! Cast bless or use magic."}
        | leave
    else if Name >< insulate then RunActEffects<=0
    else if Name >< onAttack then when $onAttack: $effect{$onAttack T T.xyz}
    else if Name >< onHit then
      if $range><1 and $xyz.2-T.xyz.2>1 then
        | $shot_missile{Target [boulder]
                        [shell [hit user] [impact explosion] [sound explosion]]}
      else
        | $effect{$onHit T T.xyz}
    else if Name >< missile then
      | $shot_missile{(Target or XYZ) Args Es}
      | Es <= []
    else if Name >< target then T <= Target
    else if Name >< host then T <= $host
    else if Name >< self then T <= Me
    else if Name >< tenant then
      | Block = $world.block_at{XYZ}
      | less Block: _goto end
      | T <= Block
    else if Name >< same_z then | XYZ <= XYZ.deep_copy; XYZ.2 <= Me.xyz.2
    else if Name >< pentagram then
      | P = $owner.pentagram
      | when P.removed: _goto end
      | XYZ.init{P.xyz}
      | Target <= P
      | T <= Target
    else if Name >< all_alive then
      | for U $world.active: when U.alive:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< hydra_targets then
      | D = (TargetXYZ-$xyz){?sign}
      | DD = D.1,D.0,D.2
      | for XYZ [$xyz+DD $xyz-DD]
        | B = $world.block_at{XYZ}
        | when B: $effect{Es B B.xyz}
      | $effect{Es T XYZ}
      | _goto end
    else if Name >< owner_units then
      | OID = $owner.id
      | for U $world.active: when U.owner.id><OID:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< enemy_units then
      | OID = $owner.id
      | for U $world.active: when $is_enemy{U}:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else bad "no effect handler for [Name]{[Args]} of [Me]"
| _label end
| when RunActEffects: $run_genes{act}