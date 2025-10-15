class_name AbilityWheelManager extends Control

enum Status { ACTIVE, INACTIVE }
var _status:Status = Status.INACTIVE

@export var _gm_handle:GameManager
@export var _ability_scene:PackedScene
@export var _distance_to_center:float = 256.0


@export var _bottle_center_marker:Marker2D
@export var _all_abilities:Array[Ability]
@export var _all_inventory_abilities:Array[Ability] = []
@export var _initial_abilities:Array[AbilityData]
@export var _ability_wheel_bg:TextureRect
@export var _ability_parent:Control

@export var _enemy_bottle_center:Marker2D
@export var _enemy_bottle_button:Button
@export var _all_enemy_abilities:Array[Ability]
@export var _enemy_wheel:TextureRect

@export var _player_inventory_handle:Area2D

@export var _temp_abilities:Array[Ability]

@export var _shake_curve:Curve

var _dragged_ability:Ability
var _dragging_ability:bool = false
var _dragging_overlapping:bool = false
var _initial_drag_position:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	#Register class
	G.register_manager.emit(self)
	
	G.dragging_ability.connect(on_drag_ability)
	G.stop_dragging_ability.connect(on_stop_drag_ability)
	
	G.round_intro_start.connect(on_loot_start)
	G.round_intro_end.connect(on_loot_end)
	
	G.round_loot_start.connect(on_loot_start)
	G.round_loot_end.connect(on_loot_end)
	
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
	_temp_abilities = []
	
	for a in encounter._enemy_abilities:
		var i
		print("Adding enemy ability: "+str(a._ability_name))
		if (a._ability_type == AbilityData.Type.WHEEL_DEBUFF):
			print("WHEEL DEBUFF!")
			
			var wp = _bottle_center_marker.global_position + (Vector2.RIGHT.rotated(deg_to_rad(randf_range(0,360))) * _distance_to_center)
			i = add_ability(a,"enemy_on_player_wheel",-1,wp)
			_temp_abilities.append(i)
			#update_ability_layout_single(_bottle_center_marker,_all_abilities,i)
		else:
			i = add_ability(a,"enemy")
		#i.set_enemy()
		
	update_ability_layout_random(_enemy_bottle_center,_all_enemy_abilities)

func start_gameplay_round():
	_status = Status.ACTIVE

func end_gameplay_round():
	_status = Status.INACTIVE
	remove_all_enemy_abilities()
	for i in _temp_abilities:
		remove_ability(i)

func add_initial_abilities():
	for a in _initial_abilities:
		var i = add_ability(a,"player")
		#i.set_on_wheel()
		
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
	
func add_ability(a:AbilityData,addToTarget:String, pos:float = -1, world_pos:Vector2 = Vector2.ZERO) -> Ability:
	var instance = _ability_scene.instantiate() as Ability
	_ability_parent.add_child(instance)

	instance._ability_name = a._ability_name
	instance._ability_description = a._ability_description
	instance.set_data(a)
	instance._ability_sprite.texture = a._ability_icon
	instance._ability_name_handle.text = a._ability_name
	instance.set_magnitude(a._magnitude)
	instance.set_on_wheel()
	if (pos != -1):
		instance._wheel_placement = pos
	else:
		instance._wheel_placement = a._initial_placement
			
	print_rich("[color=CORAL] Adding ability: "+str(instance._ability_name)+" - with ability: "+str(instance))
	match addToTarget:
		"player":
			print_rich("[color=GREEN]Adding player ability: "+a._ability_name)
			_all_abilities.append(instance)
			instance.set_on_wheel()
			instance.global_position = world_pos
			instance.global_position = calculate_closest_position_on_wheel(world_pos)
		"enemy":
			print_rich("[color=BLUE]Adding enemy ability: "+a._ability_name)
			_all_enemy_abilities.append(instance)
			instance.set_enemy()
			instance.global_position = world_pos
		"enemy_on_player_wheel":
			print_rich("[color=GREEN]Adding ENEMY ability on player wheel: "+a._ability_name)
			_all_abilities.append(instance)
			instance.set_enemy()
			instance.global_position = world_pos
			instance.global_position = calculate_closest_position_on_wheel(world_pos)
		"inventory":
			print_rich("[color=RED]Adding inventory ability: "+a._ability_name)
			_all_inventory_abilities.append(instance)
			instance.set_inventory()
			instance.global_position = world_pos
			
	return instance

func move_ability(ab:Ability,from:String,to:String):
	match from:
		"player":
			match to:
				"inventory":
					if _all_abilities.has(ab):
						_all_abilities.erase(ab)
						_all_inventory_abilities.append(ab)
				"enemy":
					#NOT IMPLEMENTED
					pass
		"inventory":
			match to:
				"player":
					if _all_inventory_abilities.has(ab):
						_all_inventory_abilities.erase(ab)
						_all_abilities.append(ab)
				"enemy":
					#NOT IMPLEMENTED
					pass

func update_ability_layout_single(centerpoint:Marker2D,abilities:Array,ability:Ability):
		var wp = ability._wheel_placement
		ability.position = centerpoint.global_position + (Vector2.RIGHT.rotated(deg_to_rad(wp)) * _distance_to_center)
		ability.position -= ability.size / 2

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

		var overlapping:bool = false
		var overlapping_ability:Ability
		for a in _all_abilities:
			if (is_too_close_to_others_on_wheel(_dragged_ability,a,get_global_mouse_position()) and a != _dragged_ability):
				a.adjacency_radius_turn_red()
				overlapping_ability = a
				overlapping = true
				break
			elif a._adjacency_bonus_indicator.modulate.g < 1:
				a.adjacency_radius_turn_white()
		if overlapping:
			_dragging_overlapping = true
		else:
			_dragging_overlapping = false
		
		
		if (_dragged_ability.is_on_wheel()):
			#Break free if too far away
			if (get_global_mouse_position().distance_to(_bottle_center_marker.global_position) > _distance_to_center * 1.6 \
			and !_gm_handle.is_gameplay_phase()):
				_dragged_ability.set_free()
				goal_position = get_global_mouse_position()
			elif overlapping:
				goal_position = find_edge_of_radius(_dragged_ability,overlapping_ability,get_global_mouse_position())
			else:
				goal_position = calculate_closest_position_on_wheel(get_global_mouse_position())
		if (_dragged_ability.is_loot()):
			goal_position = get_global_mouse_position()
		if (_dragged_ability.is_in_inventory()):
			goal_position = get_global_mouse_position()
		if (_dragged_ability.is_free()):
			if (get_global_mouse_position().distance_to(_bottle_center_marker.global_position) < _distance_to_center * 1.2):
							_dragged_ability.set_on_wheel()
			goal_position = get_global_mouse_position()			
	
		_dragged_ability.global_position = lerp(_dragged_ability.global_position, goal_position, delta * 20)
		

func on_add_ability(ab:Ability, target:String, source:String):
	var new_ab = add_ability(ab._data,target,-1,ab.global_position)
	new_ab.reparent(_ability_parent)
	match target:
		"player":
			print("PLAYA!")
			#new_ab.set_on_wheel()
		"inventory":
			print("ADDING TO INVENTORY!")
			new_ab.reparent(_ability_parent)

func on_drag_ability(ab:Ability):
	if (_gm_handle.is_gameplay_phase() and !ab.is_on_wheel()):
		print("Item is not on wheel, and we're in gameplay")
		print(ab._status)
		return
		
	if (ab.is_enemy()):
		print("Item is for the enemy")
		return
		
	#if (_gm_handle.is_loot_phase() and ab.is_on_wheel()):
	#	print("Item is on the wheel")
	#	return
		
	#if (_gm_handle.is_loot_phase() or _gm_handle.is_intro_phase()):
		#highlight_abilities()
		#green_flash_abilities()
		
	G.cursor_grab_sprite.emit()
	_dragged_ability = ab
	_dragging_ability = true
	_initial_drag_position = ab.global_position
	
func calculate_closest_position_on_wheel(pos:Vector2) -> Vector2:
	var new_pos
	new_pos = pos - _bottle_center_marker.global_position
	new_pos = new_pos.normalized()
	new_pos = _bottle_center_marker.global_position + (new_pos * _distance_to_center)
	return new_pos
	
func is_too_close_to_others_on_wheel(ab:Ability,abb:Ability, pos:Vector2):
	var range = abb._data._ability_range if abb._data._ability_range > ab._data._ability_range else ab._data._ability_range 
	if (calculate_closest_position_on_wheel(pos).distance_to(abb.global_position) < range):
		return true
	return false
	
func find_edge_of_radius(ab:Ability,target:Ability, pos:Vector2):
	var range = ab._data._ability_range if ab._data._ability_range > target._data._ability_range else target._data._ability_range
	var edge_of_rad =  target.global_position + (target.global_position.direction_to(pos)*range)
	return calculate_closest_position_on_wheel(edge_of_rad)
	
func on_stop_drag_ability(ab:Ability):
	if (!is_instance_valid(_dragged_ability)):
		return
	
	#Change cursor
	G.cursor_active_sprite.emit()
	
	_dragging_ability = false
	
	if (ab.is_enemy()):
		return
		
	if (_gm_handle.is_loot_phase() or _gm_handle.is_intro_phase()):
		highlight_abilities(true)
		
	var new_pos:Vector2 = calculate_closest_position_on_wheel(ab.global_position)
	
	var find_closest_in_range:Callable = (func(b):
		for a in _all_abilities:
			var distance = Vector2(a.global_position - b.global_position).length()
			#Replace ability
			if distance < G.ability_size:
				return a
		return null
		)
	
	var ability_to_replace:Ability = null
	if (ab.is_loot()):
		ability_to_replace = find_closest_in_range.call(ab)
		#On found an ability to replace!
		if (is_instance_valid(ability_to_replace)):
			new_pos = ability_to_replace.global_position
			#If ability is the same, bump up the level instead
			if (ability_to_replace._data._ability_name == ab._data._ability_name):
				ability_to_replace.adjust_ability_level(1)
				ability_to_replace = null
				G.single_loot_picked.emit()
			else:
				G.add_ability.emit(ab,"player","loot")
			ab.green_flash()
		else:
			#Check if you should be able to place on wheel
			if ab.global_position.distance_to(_bottle_center_marker.global_position) < (_distance_to_center * 1.2):
				ab.set_on_wheel()
				new_pos = ab.global_position
				G.add_ability.emit(ab,"player","loot")
			#Check if you place in your inventory
			elif ab.global_position.distance_to(_player_inventory_handle.global_position) < 200.0:
				new_pos = ab.global_position
				ability_to_replace = ab
				G.add_ability.emit(ab,"inventory","loot")
			else:
				new_pos = _initial_drag_position
	elif ab.is_in_inventory():
		if ab.global_position.distance_to(_bottle_center_marker.global_position) < (_distance_to_center * 1.2):
			#ab.set_inventory()
			new_pos = ab.global_position
			ability_to_replace = find_closest_in_range.call(ab)
			if (ability_to_replace):
				if ability_to_replace._ability_name == ab._ability_name:
					ability_to_replace.adjust_ability_level(1)
					ability_to_replace = null
					remove_ability(ab)
			else:
				ability_to_replace = ab
				G.add_ability.emit(ab,"player","inventory")
		else:
			new_pos = _initial_drag_position
	elif ab.is_free():
		if ab.global_position.distance_to(_player_inventory_handle.global_position) < (_distance_to_center * 1.2):
			new_pos = _dragged_ability.global_position
			move_ability(_dragged_ability,"player","inventory")
			_dragged_ability.set_inventory()
		else:
			new_pos = _initial_drag_position
			move_ability(_dragged_ability,"inventory","player")
			_dragged_ability.set_on_wheel()
			
	SimonTween.start_tween(ab,"global_position",new_pos,0.25)
	ab.bright_flash()
	await SimonTween.start_tween(ab,"scale",Vector2(0.2,0.2),0.50,_shake_curve).set_relative(true).tween_finished
	if (is_instance_valid(ability_to_replace)):
		remove_ability(ability_to_replace)
		
	_dragged_ability = null
	_dragging_ability = false

func highlight_abilities(reverse:bool = false):
	for a in _all_abilities:
		if (reverse):
			a.set_dehighlight()
		else:
			a.set_highlight()

func green_flash_abilities():
	for a in _all_abilities:
			a.green_flash()

func on_loot_start():
	highlight_abilities(true)
	
func on_loot_end():
	highlight_abilities(false)

func on_start_encounter(enc:EnemyData):
	add_encounter_abilities(enc)
