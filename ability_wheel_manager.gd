class_name AbilityWheelManager extends Control

enum Status { ACTIVE, INACTIVE }
var _status:Status = Status.INACTIVE

@export var _gm_handle:GameManager
@export var _ability_scene:PackedScene
@export var _distance_to_center:float = 256.0


@export var _bottle_center_marker:Marker2D
@export var _all_abilities:Array[Ability]
@export var _initial_abilities:Array[AbilityData]
@export var _ability_wheel_bg:TextureRect
@export var _ability_parent:Control

@export var _enemy_bottle_center:Marker2D
@export var _enemy_bottle_button:Button
@export var _all_enemy_abilities:Array[Ability]
@export var _enemy_wheel:TextureRect

@export var _shake_curve:Curve

var _dragged_ability:Ability
var _dragging_ability:bool = false
var _initial_drag_position:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	G.dragging_ability.connect(on_drag_ability)
	G.stop_dragging_ability.connect(on_stop_drag_ability)
	
	G.add_ability.connect(on_add_ability)
	G.start_encounter.connect(on_start_encounter)
	
	initialize()
	initialize_enemy()

func initialize():
	add_initial_abilities()
	setup_ability_rect(_bottle_center_marker,_ability_wheel_bg)

func initialize_enemy():
	_enemy_bottle_button.rotation = deg_to_rad(randf_range(0,360))
	setup_ability_rect(_enemy_bottle_center,_enemy_wheel)

func add_encounter_abilities(encounter:EnemyData):
	print_rich("[color=CORAL]OK, enemy encounter: "+str(encounter._description))
	#remove_all_enemy_abilities()
	
	for a in encounter._enemy_abilities:
		var i
		if (a._ability_type == AbilityData.Type.DEBUFF):
			i = add_ability(a,true,randf_range(0,360))
		else:
			i = add_ability(a,false)
		i.set_enemy()
		
	update_ability_layout_random(_enemy_bottle_center,_all_enemy_abilities)
	update_ability_layout_distributed(_bottle_center_marker,_all_abilities)

func start_gameplay_round():
	_status = Status.ACTIVE

func end_gameplay_round():
	_status = Status.INACTIVE
	remove_all_enemy_abilities()

func add_initial_abilities():
	for a in _initial_abilities:
		var i = add_ability(a)
		i.set_on_wheel()
		
	#update_ability_layout_distributed()
	update_ability_layout_random(_bottle_center_marker,_all_abilities)
	
func remove_all_enemy_abilities():
	var _a_e_a = _all_enemy_abilities.duplicate()
	for a in _a_e_a:
		remove_enemy_ability(a)
	_all_enemy_abilities = []
	
func remove_enemy_ability(a:Ability):
	_all_enemy_abilities.erase(a)
	a.destroy()
	
func remove_all_abilities():
	var _a_a = _all_abilities.duplicate()
	for a in _a_a:
		remove_ability(a)
	_all_abilities = []
	
func remove_ability(a:Ability):
	_all_abilities.erase(a)
	a.destroy()
	
func add_ability(a:AbilityData,addToPlayer:bool = true, pos:float = -1) -> Ability:
	var instance = _ability_scene.instantiate() as Ability
	_ability_parent.add_child(instance)

	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance._data = a
	instance._ability_sprite.texture = a._ability_icon
	instance.set_magnitude(a._magnitude)
	if (pos != -1):
		instance._wheel_placement = pos
	else:
		instance._wheel_placement = a._initial_placement
	print_rich("[color=CORAL] Adding ability: "+str(instance._ability_name)+" - with ability: "+str(instance))
	if (addToPlayer):
		_all_abilities.append(instance)
	else:
		_all_enemy_abilities.append(instance)
	return instance

func update_ability_layout_distributed(centerpoint:Marker2D,abilities:Array):
	for i in range(abilities.size()):
		abilities[i]._wheel_placement = (360.0 / abilities.size()) * i
		var wp = abilities[i]._wheel_placement
		
		abilities[i].position = centerpoint.global_position + (Vector2.RIGHT.rotated(deg_to_rad(wp)) * _distance_to_center)
		abilities[i].position -= abilities[i].size / 2

func update_ability_layout_random(centerpoint:Marker2D,abilities:Array):
	var random_slots:Array = []
	random_slots.resize(12)
	for i in random_slots.size():
		var increment = 360 / random_slots.size()
		random_slots[i] = increment * i# + (randf_range(-increment,increment)*0.25)
	random_slots.pop_front()
	
	for i in range(abilities.size()):
		var wp = random_slots.pick_random()
		random_slots.erase(wp)
		if abilities[i]._wheel_placement != -1:
			wp = abilities[i]._wheel_placement
		
		abilities[i].global_position = centerpoint.global_position + (Vector2.RIGHT.rotated(deg_to_rad(wp)) * _distance_to_center * centerpoint.global_transform.get_scale())

func setup_ability_rect(centerpoint:Marker2D,wheel:Control):
	wheel.size = Vector2(_distance_to_center * 2,_distance_to_center * 2)
	
	#await SimonTween.start_tween(_ability_wheel_bg,"position",_bottle_center_marker.global_position,5).tween_finished
	wheel.global_position = centerpoint.global_position
	wheel.position.x -= wheel.size.x / 2
	wheel.position.y -= wheel.size.x / 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (_dragging_ability):
		var goal_position:Vector2 = _dragged_ability.global_position
		if (_dragged_ability.is_on_wheel()):
			var skip_position_update:bool = false
			for a in _all_abilities:
				if (calculate_closest_position_on_wheel(get_global_mouse_position()).distance_to(a.global_position) < a._size and a != _dragged_ability):
					skip_position_update = true
			
			if (!skip_position_update):
				goal_position = calculate_closest_position_on_wheel(get_global_mouse_position())
		if (_dragged_ability.is_loot()):
			goal_position = get_global_mouse_position()
	
		_dragged_ability.global_position = lerp(_dragged_ability.global_position, goal_position, delta * 20)
		#_dragged_ability.global_position -= _dragged_ability.size / 2
		

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
		
	if (ab.is_enemy()):
		return
		
	_dragged_ability = ab
	_dragging_ability = true
	_initial_drag_position = ab.global_position
	
func calculate_closest_position_on_wheel(pos:Vector2) -> Vector2:
	var new_pos
	new_pos = pos - _bottle_center_marker.global_position
	new_pos = new_pos.normalized()
	new_pos = _bottle_center_marker.global_position + (new_pos * _distance_to_center)
	return new_pos
	
func on_stop_drag_ability(ab:Ability):
	if (!is_instance_valid(_dragged_ability)):
		return
	
	_dragging_ability = false
	
	if (ab.is_enemy()):
		return
		
	var new_pos:Vector2 = calculate_closest_position_on_wheel(ab.global_position)
	
	var ability_to_replace:Ability = null
	if (ab.is_loot()):
		for a in _all_abilities:
			var distance = Vector2(a.global_position - ab.global_position).length()
			if distance < G.ability_size:
				new_pos = a.global_position#calculate_closest_position_on_wheel(a.global_position)
				ability_to_replace = a
				break
				
		if (is_instance_valid(ability_to_replace)):
			G.add_ability.emit(ab,true)
		else:
			new_pos = _initial_drag_position
			
	SimonTween.start_tween(ab,"global_position",new_pos,0.25)
	ab.bright_flash()
	await SimonTween.start_tween(ab,"scale",Vector2(0.2,0.2),0.50,_shake_curve).set_relative(true).tween_finished
	if (is_instance_valid(ability_to_replace)):
		remove_ability(ability_to_replace)

func on_start_encounter(enc:EnemyData):
	print("HUH??????")
	add_encounter_abilities(enc)
