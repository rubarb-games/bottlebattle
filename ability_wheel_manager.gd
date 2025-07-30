class_name AbilityWheelManager extends Control

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
	
	add_initial_abilities()
	setup_ability_rect()

func add_initial_abilities():
	for a in _initial_abilities:
		add_ability(a)
		
	update_ability_layout()
	
func add_ability(a:AbilityData):
	var instance = _ability_scene.instantiate() as Ability
	_ability_parent.add_child(instance)

	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance._data = a
	instance._ability_sprite.texture = a._ability_icon
	print_rich("[color=CORAL] Adding ability: "+str(instance._ability_name)+" - with ability: "+str(instance))
	_all_abilities.append(instance)

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
		

func on_drag_ability(ab:Ability):
	_dragged_ability = ab
	_dragging_ability = true
	
func on_stop_drag_ability(ab:Ability):
	var new_pos = ab.global_position - _bottle_center_marker.global_position
	new_pos = new_pos.normalized()
	new_pos = _bottle_center_marker.global_position + (new_pos * _distance_to_center) - (ab.size / 2)
	SimonTween.start_tween(ab,"global_position",new_pos,0.25)
	_dragging_ability = false
