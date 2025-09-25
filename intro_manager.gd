class_name IntroManager
extends Control


@export var _intro_ui_handle:Control
@export var _ability_instance_scene:PackedScene

var _current_starter_loot:Array[Ability]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_loot(a:AbilityData) -> Ability:
	var instance = _ability_instance_scene.instantiate() as Ability
	
	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance._data = a
	instance._ability_sprite.texture = a._ability_icon
	
	instance.set_loot()
	
	_intro_ui_handle.add_child(instance)
	_current_starter_loot.append(instance)
	return instance

func remove_loot(a:Ability):
	_current_starter_loot.erase(a)

func add_encounter_loot():
	for i in range(_loot_per_encounter):
		var loot = _loot_pool.pick_random()
		var instance = add_loot(loot)
		instance.global_position = _loot_placement_marker.global_position
		instance.position.x += (_loot_spacing * i) - (_loot_per_encounter * _loot_spacing / 2)
		instance.position.x -= instance.size.x / 2
		
func on_add_ability(a:Ability,fromLoot:bool):
	if fromLoot:
		remove_loot(a)
		
		loot_picked()

func on_loot_start():
	set_skip_reward(10)
	enable_chest()
	display_loot_window()
	
func on_loot_end():
	hide_loot_window()
	for loot in _current_loot:
		loot.destroy()
	_current_loot = []
