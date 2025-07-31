class_name AbilityWheelManager extends Control

enum Status { ACTIVE, INACTIVE }
var _status:Status = Status.INACTIVE

@export var _gm_handle:GameManager

@export var _bottle_center_marker:Marker2D

@export var _distance_to_center:float = 256.0

@export var _initial_abilities:Array[AbilityData]

@export var _all_abilities:Array[Ability]

@export var _ability_scene:PackedScene

@export var _ability_parent:Control
@export var _ability_wheel_bg:TextureRect

var _dragged_ability:Ability
var _dragging_ability:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	G.dragging_ability.connect(on_drag_ability)
	G.stop_dragging_ability.connect(on_stop_drag_ability)
	
	G.add_ability.connect(on_add_ability)
	
	initialize()

func initialize():
	add_initial_abilities()
	setup_ability_rect()

func start_gameplay_round():
	_status = Status.ACTIVE

func end_gameplay_round():
	_status = Status.INACTIVE

func add_initial_abilities():
	for a in _initial_abilities:
		var i = add_ability(a)
		i.set_on_wheel()
		
	update_ability_layout()
	
func add_ability(a:AbilityData) -> Ability:
	var instance = _ability_scene.instantiate() as Ability
	_ability_parent.add_child(instance)

	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance._data = a
	instance._ability_sprite.texture = a._ability_icon
	print_rich("[color=CORAL] Adding ability: "+str(instance._ability_name)+" - with ability: "+str(instance))
	_all_abilities.append(instance)
	return instance

func update_ability_layout():
	for i in range(_all_abilities.size()):
		_all_abilities[i]._wheel_placement = (360.0 / _all_abilities.size()) * i
		var wp = _all_abilities[i]._wheel_placement
		
		_all_abilities[i].position = _bottle_center_marker.global_position + (Vector2.RIGHT.rotated(deg_to_rad(wp)) * _distance_to_center)
		_all_abilities[i].position -= _all_abilities[i].size / 2

func setup_ability_rect():
	_ability_wheel_bg.size.x = _distance_to_center * 2
	
	#await SimonTween.start_tween(_ability_wheel_bg,"position",_bottle_center_marker.global_position,5).tween_finished
	_ability_wheel_bg.position = _bottle_center_marker.global_position
	_ability_wheel_bg.position.x -= _ability_wheel_bg.size.x / 2
	_ability_wheel_bg.position.y -= _ability_wheel_bg.size.x / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (_dragging_ability):
		_dragged_ability.global_position = get_global_mouse_position()
		_dragged_ability.global_position -= _dragged_ability.size / 2
		

func on_add_ability(ab:Ability, fromLoot:bool):
	if (fromLoot):
		ab.reparent(_ability_parent)
		ab.set_on_wheel()
		_all_abilities.append(ab)
	else:
		add_ability(ab._data)

func on_drag_ability(ab:Ability):
	if (_gm_handle.is_gameplay_phase() and !ab.is_on_wheel()):
		return
		
	if (_gm_handle.is_loot_phase() and !ab.is_loot()):
		return
		
	_dragged_ability = ab
	_dragging_ability = true
	
func on_stop_drag_ability(ab:Ability):
	if (!is_instance_valid(_dragged_ability)):
		return
		
	if (ab.is_loot()):
		G.add_ability.emit(ab,true)
		
	var new_pos = ab.global_position - _bottle_center_marker.global_position
	new_pos = new_pos.normalized()
	new_pos = _bottle_center_marker.global_position + (new_pos * _distance_to_center) - (ab.size / 2)
	SimonTween.start_tween(ab,"global_position",new_pos,0.25)
	_dragging_ability = false
