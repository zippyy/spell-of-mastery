use gfx util

type tile{As Main Type Role Id Base Middle Top
          height/1 empty/0 filler/1 invisible/0 match/[same corner] shadow/0
          anim_wait/0 water/0 wall/0 bank/0 unit/0 heavy/1 lineup/1 clear/0
          parts/0 box/[64 64 h] wallShift/0 stack/0 indoor/0 liquid/0 opaque/No
          around/0 back/0 fallback/0 roof/0}
     id/Id
     main/Main
     bank/Bank
     type/Type
     role/Role
     base/Base // column base
     middle/Middle // column segment
     top/Top // column top
     height/Height
     empty/Empty
     filler/Filler //true if tile fills space, matching with other tiles
     invisible/Invisible
     shadow/Shadow
     match/Match
     anim_wait/Anim_wait
     water/Water
     wall/Wall
     around/Around
     back/Back
     unit/Unit //used for units that act as platforms
     heavy/Heavy
     lineup/Lineup
     clear/Clear
     parts/Parts
     box/Box
     wallShift/WallShift //FIXME: tile.box should be used for everything
     stack/Stack
     tiler/0
     indoor/Indoor
     liquid/Liquid
     opaque/Opaque
     fallback/Fallback
     roof/Roof
| when no $opaque: $opaque <= not $invisible
| when $box.2><h: $box.2 <= $height*8
| less $parts:
  | if $height>1
    then | $parts <= @flip: map I $height-1
           | tile As Main Type Role Id Base Middle Top
                 @[parts -(I+1) @As]
    else $parts <= []

transparentize Base Alpha =
| Empty = 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}

DummyGfx = gfx 1 1

m_same_side World X Y Z Role = World.getSidesSame{X Y Z Role}
m_same_corner World X Y Z Role = World.getCornersSame{X Y Z Role}
m_any_side World X Y Z Role = World.getSides{X Y Z}
m_any_corner World X Y Z Role = World.getCorners{X Y Z}

m_any_stairs Me X Y Z Role =
| E = `[]`
    $filled{X Y-1 Z} $filled{X+1 Y Z}
    $filled{X Y+1 Z} $filled{X-1 Y Z}
//| D = E.digits{2}
//| when [X Y]><[4 3]: say [Role [X Y Z] E]
| if E><[1 0 0 1] then
   | if $role{X+1 Y Z-4}><Role then
       | when $role{X Y+1 Z-4}<>Role: E<=[0 0 0 1]
     else if $role{X Y+1 Z-4}><Role then
       | when $role{X+1 Y Z-4}<>Role: E<=[1 0 0 0]
     else if $role{X-1 Y Z+4}><Role then E<=[0 0 0 1]
     else if $role{X Y-1 Z+4}><Role then E<=[1 0 0 0]
     else if $filled{X Y-1 Z+4} and not $filled{X-1 Y Z+4} then E<=[0 0 0 1]
     else if $filled{X-1 Y Z+4} and not $filled{X Y-1 Z+4} then E<=[1 0 0 0]
     else
  else if E><[1 1 0 0] then
     if $role{X Y-1 Z+4}><Role then E<=[1 0 0 0]
     else if $role{X+1 Y Z+4}><Role then E<=[0 1 0 0]
     else if $role{X Y+1 Z-4}><Role and not $filled{X Y+1 Z} then E<=[1 0 0 0]
     else if $role{X-1 Y Z-4}><Role and not $filled{X-1 Y Z} then E<=[0 1 0 0]
     else if $filled{X Y-1 Z+4} and not $filled{X-1 Y Z+4} then E<=[0 1 0 0]
     else if $filled{X+1 Y Z+4} and not $filled{X Y-1 Z+4} then E<=[1 0 0 0]
     else
  else if E><[0 0 1 1] then
     if $role{X-1 Y Z+4}><Role then E<=[0 0 0 1]
     else if $role{X+1 Y Z-4}><Role and not $filled{X+1 Y Z} then E<=[0 0 0 1]
     else if $role{X Y-1 Z-4}><Role and not $filled{X-1 Y Z} then E<=[0 0 1 0]
     else if $role{X Y+1 Z+4}><Role then E<=[0 0 1 0]
     else if $filled{X-1 Y Z+4} and not $filled{X Y+1 Z+4} then E<=[0 0 1 0]
     else if not $filled{X+1 Y Z-4} and $filled{X Y-1 Z-4} then E<=[0 0 1 0]
     else
  else if E><[1 0 0 0] then
     if $role{X-1 Y Z-4}><Role then E<=[0 1 0 0]
     else if $role{X Y+1 Z-4}><Role and not $filled{X Y+1 Z} then E<=[1 0 0 0]
     else if $role{X+1 Y Z-4}><Role and not $filled{X+1 Y Z} then E<=[0 0 0 1]
     else
  else if E><[0 0 0 1] then
     if $role{X-1 Y Z+4}><Role then E<=[0 0 0 1]
     else if $role{X-1 Y Z-4}><Role and not $filled{X-1 Y Z} then E<=[0 1 0 0]
     else if $role{X Y+1 Z-4}><Role and not $filled{X Y+1 Z} then E<=[1 0 0 0]
     else if $role{X Y-1 Z-4}><Role and not $filled{X Y-1 Z} then E<=[0 0 1 0]
     else
  else if E><[0 0 0 0] then
     if $role{X-1 Y Z-4}><Role then E<=[0 1 0 0]
     else if $role{X Y+1 Z-4}><Role then E<=[1 0 0 0]
     else if $role{X Y-1 Z-4}><Role then E<=[0 0 1 0]
     else
  else
| E

BelowSlope = 0
ColumnHeight = 0

tile.render X Y Z Below Above Seed =
| when $invisible
  | BelowSlope <= #@1111
  | leave 0
| World = $main.world
| less Z: ColumnHeight <= World.height{X Y}
| Limpid = 0
| TH = $height
| when Above.opaque:
  | when $type >< base_:
    | BelowSlope <= #@1111
    | leave 0
  | Z = Z-$height+1
  | A = World.at{X+1 Y Z}
  | B = World.at{X Y+1 Z}
  | C = World.at{X+1 Y+1 Z}
  | D = World.at{X+1 Y-1 Z}
  | when A.opaque and B.opaque and C.opaque and (D.opaque or D.type><border_)
         and A.height>>TH and B.height>>TH and C.height>>TH and D.height>>TH:
    | Limpid <= 1
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| NeibSlope = #@0000
| T = Me
| when $indoor and Z < ColumnHeight-1 /*and AH*/: //FIXME: non-ceil tiles?
  | T <= $indoor
| when T.water:
  | Neib,Water = T.water
  | when got World.neibs{X Y Z-TH+1}.find{?type><Neib}:
    | T <= Water
| when $back:
  | Z = Z-$height+1
  | A = World.at{X+1 Y Z}
  | B = World.at{X Y+1 Z}
  | C = World.at{X+1 Y+1 Z}
  | Ar = $around
  | when A.type><Ar or B.type><Ar or C.type><Ar:
    | T <= $back
| Gs = if BE then T.top
       else if BR <> $role or BelowSlope><#@1111 then T.base
       else if AR <> $role then T.top
       else T.middle
| Lineup = 0
| when AH and $lineup and ($lineup<>other or AR<>$role):
  | Lineup <= not Above.stack or AR <> $role
| G = if Lineup
      then | NeibSlope <= #@1111
           | Gs.NeibSlope
      else | Elev = $tiler{}{World X Y Z $role}
           | when $fallback and Elev><[1 1 1 1]:
             | Elev <= m_same_corner{World X Y Z $role}
             | Gs <= $fallback.base
           | NeibSlope <= Elev.digits{2}
           | R = Gs.NeibSlope
           | less got R: R <= Gs.#@1111
           | R
| BelowSlope <= NeibSlope
| when Limpid: leave 0
| less $anim_wait: G <= G.(Seed%G.size)
| leave G

main.tile_names Bank =
| $tiles{}{?1}.keep{?bank><Bank}{?type}.skip{$aux_tiles.?^got}.sort

main.load_tiles =
| BankNames = case $params.world.tile_banks [@Xs](Xs) X[X]
| $params.world.tile_banks <= BankNames 
| Tiles = t
| $aux_tiles <= t
| Frames = No
| T = $params.tile
| HT = T.height_
| for I 15: // object height blockers
  | T."h[I+1]_" <=
    | R = HT.deep_copy
    | R.height <= I+1
    | R
| Es = [1111 1000 1100 1001 0100 0001 0110 0011
        0010 0111 1011 1101 1110 1010 0101 0000]
| for Bank BankNames: for Type,Tile $params.Bank
  | Tile.bank <= Bank
  | Tiles.Type <= Tile
  | when got Tile.aux: $aux_tiles.Type <= Tile.aux
  | SpriteName = Tile.sprite
  | Sprite = $sprites.SpriteName
  | less got Sprite: bad "Tile [Type] references missing sprite [SpriteName]"
  | Frames = Sprite.frames
  | NFrames = Frames.size
  | Tile.gfxes <= dup 16 No
  | for CornersElevation Es: when got!it Tile.CornersElevation:
    | E = CornersElevation.digits.digits{2}
    | Is = if it.is_list then it else [it]
    | Gs = map I Is
           | less I < NFrames:
             | bad "Tile `[Type]` wants missing frame [I] in `[SpriteName]`"
           | Frames.I
    | when got!a Tile.alpha: Gs <= Gs{(transparentize ? a)}
    | when Gs.size: Tile.gfxes.E <= Gs
| $tiles <= t size/1024
| for K,V Tiles
  | Base,Middle,Top = if got V.stack then V.stack{}{Tiles.?.gfxes}
                      else | T = V.gfxes; [T T T]
  | Id = if K >< void then 0
         else | !$last_tid + 1
              | $last_tid
  | As = V.list.join
  | Tile = tile As Me K V.role^~{K} Id Base Middle Top @As
  | Tile.tiler <= case Tile.match
    [any corner] | &m_any_corner
    [any side] | &m_any_side
    [same corner] | &m_same_corner
    [same side] | &m_same_side
    [any stairs] | &m_any_stairs
    Else | bad "tile [K] has invalid `match` = [Else]"
  | $tiles.K <= Tile
| for K,T $tiles
  | when T.indoor:
    | T.indoor <= $tiles.(T.indoor)
    | less got T.indoor: say "tile [K] references unknown indoor tile"
  | when T.water:
    | T.water <= [T.water.0 $tiles.(T.water.1)]
    | less got T.water: say "tile [K] references unknown water tile"
  | when T.back: T.back <= $tiles.(T.back)
  | when T.fallback: T.fallback <= $tiles.(T.fallback)
  | when T.roof.is_list: T.roof <= [T.roof.0 $tiles.(T.roof.1)]

export tile
