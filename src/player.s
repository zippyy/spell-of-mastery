use bits

type ai{player} world
| $world <= $player.world
| $params.aiSwapXYZ <= [0 0 0]
| $params.view <= [0 0 0]
| $params.cursor <= [0 0 1]

ai.main = $player.main
ai.params = $player.params

ai.picked = $player.picked
ai.`!picked` V = $player.picked <= V

ai.clear =
| $params.aiSwapXYZ.init{[0 0 0]}
| $params.aiType <= 'default'
| $params.aiStep <= 0
| $params.aiWait <= 0
| $params.aiSpellWait <= 0 //hack to stop AI from spamming spells
| $params.aiLastTurn <= -1
| $params.difficulty <= 6 // 5 is normal, 0 is impossible, 10 is very easy

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world}
   name ai human color mana income upkeep
   moves //use to be number for creatues movable per turn; currently obsolete
   leader
   pentagram
   params
   research/(t) //research and latency
   picked_ //picked units
   sight // fog of war
| $name <= if $id >< 0 then "Independents" else "Player[$id]"
| $color <= PlayerColors.$id
| $params <= t
| $sight <= dup 132: 132.bytes
| $ai <= ai Me
| $clear

player.picked = $picked_.unheap
player.`!picked` Us =
| for U $picked_: U.picked <= 0
| for U Us: U.picked <= 1
| Us = Us.enheap
| $picked_.heapfree
| $picked_ <= Us

player.is_enemy P = $id <> P.id

player.notify Text =
| less $human: leave
| $world.notify{Text}

player.main = $world.main

player.researching = $params.researching
player.`!researching` R = $params.researching <= R

player.lore = $params.lore
player.`!lore` R = $params.lore <= R

player.explore State =
| when State
  | for S $sight: S.clear{3}
  | for U $units: U.explore{1}
  | leave
| for S $sight: S.clear{0}
| for U $units: U.explore{1}


player.explored X,Y,Z = $sight.Y.X

player.clear =
| for Xs $sight: Xs.clear{3}
| $ai.clear
| $picked <= []
| $leader <= 0
| $pentagram <= 0
| $researching <= 0
| $mana <= 0
| $income <= 0
| $upkeep <= 0
| $lore <= 0
| $params.lossage <= 0
| $params.mana <= 0
| for Type,Act $main.params.acts: $research.Type <= 0


player.got_income A =
| !$income + A
| when A < 0: !$upkeep + A

player.lost_income A =
| !$income - A
| when A < 0: !$upkeep - A

player.got_unit U =
| $got_income{U.income}

player.lost_unit U =
| when U.ai >< pentagram: $pentagram <= 0
| $lost_income{U.income}

player.recalc =
| $income <= 0
| $upkeep <= 0
| $pentagram <= 0
| $leader <= 0
| for U $units
  | when U.ai >< pentagram: $pentagram <= U
  | when U.leader: $leader <= U
  | $got_income{U.income}
  | U.move_in{1}

player.research_item What =
| Act = $main.params.acts.What
| $research.What <= Act.research
| $notify{"Acquired [Act.title]"}

player.research_remain Act =
| ResearchSpent = $research.(Act.name)
| ResearchRemain = Act.research - ResearchSpent
| ResearchRemain

player.active =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and ?moved < Turn
                           and not ?removed)}
player.units =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and not ?removed)}


export player