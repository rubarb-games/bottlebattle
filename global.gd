extends Node

signal display_tooltip(text:String)
signal hide_tooltip()

signal execute_ability(ability:AbilityData,combo:int)

signal popup_text(text:String, pos:Vector2)

signal dragging_ability(ab:Ability)
signal stop_dragging_ability(ab:Ability)
