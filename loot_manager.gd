class_name LootManager extends Control

enum Status { ACTIVE, INACTIVE }
var _status:Status = Status.INACTIVE

@export var _gm_handle:GameManager

#INTRO LOOT!

@export var _intro_ui_handle:Control
@export var _intro_loot_placement_marker:Marker2D
@export var _intro_bottle_placement_marker:Marker2D

var _current_starter_loot:Array[Ability]
var is_intro:bool = false
#NORMAL LOOT!

@export var _loot_window:Control
@export var _loot_skip_button:Button
@export var _loot_chest_button:Button
@export var _loot_chest_help_text:RichTextLabel

var _loot_picked_amount:int = 0
var _loot_picked_maximum:int = 1
var _skip_reward:int = 10
var _pressed_chest_button:bool = false

@export var _loot_placement_marker:Marker2D
@export var _loot_spacing:float = 40.0

@export var _bottle_pool:Array[Bottle]
@export var _current_bottles:Array[BottleLoot]
@export var _bottle_choices:int = 2

@export var _loot_pool:Array[AbilityData]
var _loot_rarity_treshold:AbilityData.Rarity = AbilityData.Rarity.NORMAL
@export var _loot_per_encounter:int = 3

@export var _ability_instance_scene:PackedScene
@export var _bottle_instance_scene:PackedScene

@export var _current_loot:Array[Ability]

@export var _chest_open_curve:Curve

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Register class
	G.register_manager.emit(self)
	
	G.round_loot_start.connect(on_loot_start)
	G.round_loot_end.connect(on_loot_end)
	
	G.round_intro_start.connect(on_intro_start)
	G.round_intro_end.connect(on_intro_end)
	
	G.add_ability.connect(on_add_ability)
	G.add_bottle.connect(on_add_bottle)
	
	_loot_skip_button.pressed.connect(on_pressed_skip_button)
	_loot_chest_button.pressed.connect(on_pressed_chest_button)
	
	_intro_ui_handle.visible = false
	_loot_window.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_loot(a:AbilityData, is_intro:bool = false) -> Ability:
	var instance = _ability_instance_scene.instantiate() as Ability
	
	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance._data = a
	instance._ability_sprite.texture = a._ability_icon
	
	instance.set_loot()
	
	#_loot_window
	if (is_intro):
		_intro_ui_handle.add_child(instance)
		_current_starter_loot.append(instance)
	else:
		_loot_window.add_child(instance)
		_current_loot.append(instance)
	return instance

func add_bottle_loot(b:Bottle, is_intro:bool = false) -> BottleLoot:
	var instance = _bottle_instance_scene.instantiate() as BottleLoot
	
	instance.setup_bottle(b)
	
	#instance.set_loot()
	
	#_loot_window
	if (is_intro):
		_intro_ui_handle.add_child(instance)
		_current_bottles.append(instance)
	return instance

func remove_loot(a:Ability, is_intro:bool = false):
	if (is_intro):
		_current_starter_loot.erase(a)
	else:	
		_current_loot.erase(a)

func remove_bottle(b:BottleLoot):
	_current_bottles.erase(b)

func add_encounter_loot(is_intro:bool = false):
	
	#FILTER THE LOOT TABLE FOR CERTAIN RARITIES!
	var current_loot_table = _loot_pool
	if is_intro:
		_loot_rarity_treshold = AbilityData.Rarity.RARE
		current_loot_table = _loot_pool.filter(ability_filter_by_rarity)
		if current_loot_table.size() == 0:
			return
	else:
		_loot_rarity_treshold = AbilityData.Rarity.NORMAL
		current_loot_table = _loot_pool.filter(ability_filter_by_rarity)
	
	
	for i in range(_loot_per_encounter):
		var loot = current_loot_table.pick_random()
		var instance = add_loot(loot,is_intro)
		if (is_intro):
			instance.global_position = _intro_loot_placement_marker.global_position
		else:
			instance.global_position = _loot_placement_marker.global_position
		instance.position.x += (_loot_spacing * i) - (_loot_per_encounter * _loot_spacing / 2)
		instance.position.x -= instance.size.x / 2


func add_bottles():
	for i in range(_bottle_choices):
		var loot = _bottle_pool.pick_random()
		var instance = add_bottle_loot(loot,is_intro)
		if (is_intro):
			instance.global_position = _intro_bottle_placement_marker.global_position
		else:
			instance.global_position = _intro_bottle_placement_marker.global_position
		instance.position.x += (_loot_spacing * i) - (_loot_per_encounter * _loot_spacing / 2)
		instance.position.x -= instance.size.x / 2

func loot_picked():
	_loot_picked_amount += 1
	if (_loot_picked_amount >= _loot_picked_maximum):
		if is_intro:
			G.intro_loot_picked.emit()
		else:
			G.loot_picked.emit()
	#G.round_gameplay_start.emit()

func display_loot_window():
	_loot_window.visible = true
	
func hide_loot_window():
	_loot_window.visible = false

func on_pressed_skip_button():
	G.adjust_cash.emit(_skip_reward)
	loot_picked()

func set_skip_reward(rew:int):
	_skip_reward = rew
	_loot_skip_button.text = "SKIP " + "("+str(_skip_reward)+"c bonus)"

func disable_chest():
	SimonTween.start_tween(_loot_chest_help_text,"modulate:a",1.0,0.5,null)
	_loot_chest_button.disabled = true
	_loot_chest_button.visible = false

func enable_chest():
	_loot_chest_help_text.modulate.a = 0.0
	_loot_chest_button.disabled = false
	_loot_chest_button.visible = true
	
func ability_filter_by_rarity(loot:AbilityData):
	if (loot.rarity == _loot_rarity_treshold):
		return true
	else:
		return false
	
func on_pressed_chest_button():
	
	await SimonTween.start_tween(_loot_chest_button,"rotation",deg_to_rad(60),1.0,_chest_open_curve).set_start_snap(true).set_relative(true).tween_finished
	disable_chest()
	add_encounter_loot()
	set_skip_reward(0)
	_pressed_chest_button = true
	
func on_add_ability(a:Ability,fromLoot:bool):
	if fromLoot:
		remove_loot(a)
		
		loot_picked()

func on_add_bottle(b:BottleLoot):
	remove_bottle(b)
	loot_picked()

func on_intro_start():
	_intro_ui_handle.visible = true
	_loot_picked_amount = 0
	_loot_picked_maximum = 1
	_intro_ui_handle.modulate.a  = 1.0
	is_intro = true
	add_encounter_loot(true)
	add_bottles()
	
func on_intro_end():
	is_intro = false
	_intro_ui_handle.modulate.a  = 0.0

func on_loot_start():
	_loot_picked_amount = 0
	_loot_picked_maximum = 1
	set_skip_reward(10)
	enable_chest()
	display_loot_window()
	
func on_loot_end():
	hide_loot_window()
	for loot in _current_loot:
		loot.destroy()
	_current_loot = []
