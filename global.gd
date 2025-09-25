extends Node

var ability_size = 40

var anim_speed_fast = 0.3
var anim_speed_slow = 1.0

signal display_tooltip(text:String)
signal hide_tooltip()

signal execute_ability(ability:Ability,combo:int)
signal loot_picked()
signal intro_loot_picked()

signal start_encounter(encounter:EnemyData)

signal popup_text(text:String, pos:Vector2)
signal display_status_text(text:String)

signal popup_round_timer_text(text:String)

signal dragging_ability(ab:Ability)
signal stop_dragging_ability(ab:Ability)

signal dragging_bottle(b:BottleLoot)
signal stop_dragging_bottle(b:BottleLoot)

signal add_ability(ab:Ability,fromLoot:bool)
signal add_bottle(b:BottleLoot)

signal buff_created(b:Buff)
signal buff_elapsed(b:Buff)

signal next_turn_started()

signal adjust_cash(cash_adjustment:int)

signal flash_bottle()
signal flash_bottle_green()

signal round_new_start()
signal round_new_end()

signal round_intro_end()
signal round_intro_start()

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

signal register_manager(obj:Object)
