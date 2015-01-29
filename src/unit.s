use util

type unit.$class{Id World}
  id/Id // numeric id for octree
  world/World
  serial
  class
  xyz/[0 0 -1] // world coordinates
  sub_xyz/[0 0 0] // fine X,Y,Z
  next // next unit inside of this world cell
  column_next // next unit inside of this world column
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  frame
  facing // direction this unit faces
  slope // unit is standing on a sloped terrain
  flipX
  owner // player controlling this unit
  picked // cons of the next unit in the selection
  active // cons used to hold this unit inside the world active units list
  order_what // pending order
  order_xyz/[0 0 0]
  action
  action_target/[0 0 0]
  action_cycles // cycles left till action is complete
  from_xyz/[0 0 0]

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.init Class =
| $class <= Class
| $flipX <= 0
| $facing <= 0
| $next <= 0
| $column_next <= 0
| $serial <= $world.serial
| !$world.serial - 1
| $animate{still}
| $active <= No

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| $anim_step <= 0
| AnimFrame = $anim_seq.$anim_step
| $frame <= $sprite.frames.AnimFrame

unit.free = $world.free_unit{Me}

unit.remove =
| $world.remove_unit{Me}
| when $picked: $picked <= $pick^uncons{picked}.skip{?id >< $id}^cons{picked}
| $xyz.2 <= -1

unit.removed = $xyz.2 >< -1

unit.move XYZ =
| $remove
| $xyz.init{XYZ}
| $sub_xyz.init{[0 0 0]}
| $world.place_unit{Me}
| $environment_updated

unit.environment_updated =
| [UX UY UZ] = $xyz
| $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@1111 => 0

unit.render FB X Y =
| G = $frame
| XX = X+32-G.w/2 
| YY = Y-16-G.h+$slope*16
| when $picked: FB.rect{#00FF00 0 XX YY G.w G.h}
| FB.blit{XX,YY G flipX/$flipX}

unit.order Action =
| Action.unit <= Me
| $ordered <= Action
| less got $active
  | $active <= $world.active
  | $world.active <= Me


export unit