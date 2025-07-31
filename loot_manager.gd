class_name LootManager extends Control

enum Status { ACTIVE, INACTIVE }
var _status:Status = Status.INACTIVE

@export var _gm_handle:GameManager

@export var _loot_window:Control
@export var _loot_spacing:float = 40.0

@export var _loot_pool:Array[AbilityData]
@export var _loot_per_encounter:int = 3

@export var _ability_instance_scene:PackedScene

@export var _current_loot:Array[Ability]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.round_loot_start.connect(on_loot_start)
	G.round_loot_end.connect(on_loot_end)
	
	G.add_ability.connect(on_add_ability)

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
	
	_loot_window.add_child(instance)
	_current_loot.append(instance)
	return instance

func remove_loot(a:Ability):
	_current_loot.erase(a)

func add_encounter_loot():
	for i in range(_loot_per_encounter):
		var loot = _loot_pool.pick_random()
		var instance = add_loot(loot)
		instance.position.x = _loot_spacing * i

func loot_picked():
	G.round_gameplay_start.emit()

func display_loot_window():
	_loot_window.visible = true
	
func hide_loot_window():
	_loot_window.visible = false

func on_add_ability(a:Ability,fromLoot:bool):
	if fromLoot:
		remove_loot(a)
		
		loot_picked()

func on_loot_start():
	display_loot_window()
	add_encounter_loot()
	
func on_loot_end():
	hide_loot_window()
	for loot in _current_loot:
		loot.destroy()
	_current_loot = []
