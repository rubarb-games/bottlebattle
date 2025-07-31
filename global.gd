extends Node

signal display_tooltip(text:String)
signal hide_tooltip()

signal execute_ability(ability:AbilityData,combo:int)

signal popup_text(text:String, pos:Vector2)

signal dragging_ability(ab:Ability)
signal stop_dragging_ability(ab:Ability)

signal add_ability(ab:Ability,fromLoot:bool)

signal round_gameplay_end()
signal round_gameplay_start()

signal round_loot_start()
signal round_loot_end()

signal round_other_start()
signal round_other_end()

signal round_gameover_start()
signal round_gameover_end()

signal player_die()
signal enemy_die()
