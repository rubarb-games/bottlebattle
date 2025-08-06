class_name BottleManager extends Control

enum BottleStatus { IDLE, CHARGING, SPINNING, INACTIVE, IN_PROGRESS, EVALUATING, ENEMY_TURN }
var _status:BottleStatus = BottleStatus.INACTIVE

@export var _ability_wheel_manager_handle:AbilityWheelManager
@export var _gm_handle:GameManager

@export var _button_handle: Button
@export var _bottle_center:Marker2D
@export var _all_bottle_handle:Control

@export var _all_bottles_handle:Control

@export var _all_enemy_bottle_handle:Control
@export var _enemy_bottle_center:Marker2D
@export var _enemy_button_handle:Button
var _enemy_initial_spin_time:Vector2 = Vector2(0.5,1.2)
var _enemy_spin_time_target:float = 0.0
var _enemy_spin_time:float = 0.0
var _enemy_spin_force:float = 0.0

var _speed_charging_treshold:float = 5
var _speed_treshold:float = 50.0
var _time_between_rounds:float = 0.5

@export var _spin_curve:Curve
@export var _shake_curve:Curve
@export var _speed_buildup_falloff_curve:Curve
@export var _spin_falloff_curve:Curve
@export var _mouse_velocity_curve:Curve
@export var _strike_curve:Curve
@export var _distance_curve_falloff:Curve
@export var _enemy_spin_falloff:Curve
@export var _bottle_flash_curve:Curve

@export var _status_label:Label
@export var _charging_label:Label
@export var _debug_handle_a: Label
@export var _debug_handle_b: Label
@export var _debug_handle_c: Label

@export var ability_arr:Array[ColorRect]
var target_ability:ColorRect

var _combo_number: int = 0
var _total_degrees_spun: float = 0.0
@export var _combo_counter_handle:Label
@export var _combo_handle:Control
@export var _crit_handle:Label
@export var _bottle_flash_handle:ColorRect

var _initial_spin_velocity:float = 0.0
var _spinning_timer:float = 0.0
@export var _spinning_timer_max:float = 3.5

var _main_click_pressed: bool = false
var _secondary_click_pressed: bool = false

var _last_mouse_position: Vector2 = Vector2.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var _mouse_dampen_multipler:float = 5.0
var _mouse_speed_buildup: Vector2 = Vector2.ZERO

var _mouse_speed_multiplier: float = 1000.0

var _bottle_rotation_multiplier: float = 3.5
var _bottle_dampen_multiplier: float = 3.0
var _bottle_angular_velocity:float = 0.0
var _bottle_angular_velocity_treshold:float = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	#G.round_gameplay_start.connect(on_game)
	
	reset_values()
	
	#change_state(BottleStatus.IDLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (_gm_handle._player_status != GameManager.PlayerStatus.IDLE \
	or _gm_handle._round_status != GameManager.RoundStatus.GAMEPLAY):
		return
	
	match _status:
		BottleStatus.IDLE:
			#check_rotation()
			get_input_idle(delta)
			calculate_bottle_rotation(delta)
			check_idle_state()
		BottleStatus.CHARGING:
			get_input_charging(delta)
			calculate_bottle_rotation(delta)
			check_charging_state()
			update_charging_power_label(delta)
		BottleStatus.SPINNING:
			spin_bottle(delta)
			check_spinning()
		BottleStatus.IN_PROGRESS:
			pass
		BottleStatus.INACTIVE:
			pass
		BottleStatus.EVALUATING:
			pass
		BottleStatus.ENEMY_TURN:
			process_enemy(delta)

func get_input(delta):
	if (Input.is_action_just_pressed("main_click")):
		_mouse_speed_buildup = Vector2.ZERO
		_main_click_pressed = true
	elif (Input.is_action_just_released("main_click")):
		_main_click_pressed = false
		#check_rotation()
		
	if (Input.is_action_just_pressed("right_click")):
		_secondary_click_pressed = true
	elif (Input.is_action_just_released("right_click")):
		_secondary_click_pressed = false

	get_mouse_delta(_main_click_pressed, delta)
		
func get_input_idle(delta):
	get_input(delta)

func get_input_charging(delta):
	get_input(delta)

func check_charging_state():
	if (!_main_click_pressed and abs(_bottle_angular_velocity) > _speed_charging_treshold):
		change_state(BottleStatus.SPINNING)
		
	if (!_main_click_pressed and abs(_bottle_angular_velocity) < _speed_charging_treshold):
		change_state(BottleStatus.IDLE)
	
func check_idle_state():
	if (_main_click_pressed and abs(_bottle_angular_velocity) > _speed_charging_treshold):
		change_state(BottleStatus.CHARGING)

func change_state(state:BottleStatus):
	match state:
		BottleStatus.IDLE:
			SimonTween.start_tween(_all_bottle_handle,"modulate",Color.WHITE,1)
			_status_label.text = "BOTTLE IS IDLE!"
			reset_values()
			shrink_charge_value()
			_status = state
		BottleStatus.CHARGING:
			SimonTween.start_tween(_all_bottle_handle,"modulate",Color.WHITE,1)
			flash_bottle()
			_status_label.text = "CHARGING!"
			_status = state
		BottleStatus.SPINNING:
			flash_bottle()
			_status_label.text = "SPINNING!"
			_spinning_timer = 0.0
			_total_degrees_spun = 0.0
			_initial_spin_velocity = _bottle_angular_velocity 
			_status = state
		BottleStatus.IN_PROGRESS:
			_status = state
		BottleStatus.INACTIVE:
			SimonTween.start_tween(_all_bottle_handle,"modulate",Color.DIM_GRAY,1)
			_status = state
		BottleStatus.EVALUATING:
			_status_label.text = "BOTTLE IS EVALUATING!"
			shrink_charge_value()
			eval_direction()
			_status = state
		BottleStatus.ENEMY_TURN:
			await get_tree().create_timer(_time_between_rounds).timeout
			_status = state
			setup_enemy_spin()
			_status_label.text = "ENEMY TURN!"

func start_gameplay_round():
	change_state(BottleStatus.IDLE)
	
func end_gameplay_round():
	change_state(BottleStatus.INACTIVE)

func reset_values():
	reset_combo()
	
	_bottle_flash_handle.modulate.a = 0
	_mouse_speed_buildup = Vector2.ZERO
	_bottle_angular_velocity = 0.0
	_last_mouse_position = get_global_mouse_position()
	_main_click_pressed = false
	
	_charging_label.scale = Vector2.ZERO

func check_rotation():
	if (_bottle_angular_velocity >= _bottle_angular_velocity_treshold):
		change_state(BottleStatus.SPINNING)

func check_spinning():
	if (_bottle_angular_velocity <= 0.05):
		change_state(BottleStatus.EVALUATING)

func calculate_bottle_rotation(delta):
	#get direction from angle
	var bottle_dir:Vector2 = Vector2.RIGHT.rotated( _bottle_center.rotation) 
	#var bottle_cross = _spin_curve.sample(bottle_dir.dot(_mouse_speed_buildup))
	
	#Get the mouse axis that has the strongest direction
	#var max_axis
	#if (_mouse_speed_buildup.normalized().abs().x >= _mouse_speed_buildup.normalized().abs().y): 
	#	max_axis = _mouse_speed_buildup.normalized().x
	#else:
	#	max_axis = _mouse_speed_buildup.normalized().y * -1
	#max_axis *= -1
	#bottle_cross = _spin_curve.sample(max_axis)
	
	#Get mouse relative to center
	var mouse_pos = get_global_mouse_position()
	var distance:Vector2 =  _bottle_center.global_position - mouse_pos
	var dir:Vector2 = distance.normalized()
	dir = dir.rotated(deg_to_rad(-90))
	var speedEval = _spin_curve.sample(dir.dot(_mouse_speed_buildup.normalized()))
	#REVISE THIS WITH SOMETHING BETTER!!!
	#THIS ADDS TO THE VELOCITY
	#* _mouse_speed_buildup.length()
	var tempMultiplier = _bottle_rotation_multiplier * (1 - _speed_buildup_falloff_curve.sample(_bottle_angular_velocity / _speed_treshold))
	var tempVelocity = deg_to_rad(speedEval * tempMultiplier * _mouse_speed_buildup.length())
	
	_bottle_angular_velocity = lerp(_bottle_angular_velocity,_bottle_angular_velocity+tempVelocity, delta)
	dampen_bottle_spin(delta)
#_bottle_angular_velocity = clamp(lerp(_bottle_angular_velocity,0.0,delta*0.1),-_bottle_angular_velocity_treshold*10, _bottle_angular_velocity_treshold*10)
	
	_button_handle.rotation +=  _bottle_angular_velocity * delta# * _bottle_rotation_multiplier
	
func dampen_bottle_spin(delta):
	#if (_main_click_pressed):
	#	return
	#THIS JUST DAMPENS THE ANGULAR VELOCITY
	if (_bottle_angular_velocity >= 0):
		_bottle_angular_velocity = clamp(_bottle_angular_velocity - (delta * _bottle_dampen_multiplier),0,_speed_treshold)
	else:
		_bottle_angular_velocity = clamp(_bottle_angular_velocity + (delta * _bottle_dampen_multiplier),-_speed_treshold,0)
	
	#_bottle_angular_velocity = clamp(_bottle_angular_velocity,-_bottle_angular_velocity_treshold,_bottle_angular_velocity_treshold)
	
	
func get_mouse_delta(is_mouse_clicked:bool, delta):
	var mouse_position = get_global_mouse_position()
	_mouse_delta = mouse_position - _last_mouse_position
	_last_mouse_position = mouse_position
	
	if (is_mouse_clicked):
		var mouse_force = _mouse_speed_buildup.length()
		#_mouse_delta * delta * _mouse_speed_multiplier
		_mouse_speed_buildup += (_mouse_delta * delta * _mouse_speed_multiplier)
	_mouse_speed_buildup = lerp(_mouse_speed_buildup,Vector2.ZERO,delta * _mouse_dampen_multipler)
	_debug_handle_a.text = "Mouse speed: "+str(Vector2(roundf(_mouse_speed_buildup.x*100)/100,roundf(_mouse_speed_buildup.y*100)/100))

	
func update_charging_power_label(delta):
	_charging_label.text = str(roundf(_bottle_angular_velocity))
	var scale_factor = (_bottle_angular_velocity / _bottle_angular_velocity_treshold)
	_charging_label.scale = Vector2(1 + scale_factor,1 + scale_factor)
	
	_charging_label.rotation = deg_to_rad(randf_range(-scale_factor,scale_factor))
	pass

func spin_bottle(delta):
	_spinning_timer += delta
	_bottle_angular_velocity = clamp(lerp(_initial_spin_velocity,0.0,_spin_falloff_curve.sample(_spinning_timer)),-50, 50)
	_button_handle.rotation += _bottle_angular_velocity * delta
	
	_total_degrees_spun += rad_to_deg(_bottle_angular_velocity * delta)
	if (_total_degrees_spun > 360.0):
		if (_combo_handle.modulate.a < 1):
			#print("HELL YEAH; MORE COMMMMB")
			SimonTween.start_tween(_combo_handle,"modulate:a",1.0,0.25)
		_total_degrees_spun -= 360
		_combo_number += 1
		_combo_counter_handle.text = str(_combo_number)+"x \n SPINS!"
		SimonTween.start_tween(_combo_counter_handle,"scale",Vector2(0.2,0.2),0.4,_shake_curve).set_relative(true)

func eval_direction():
	var top_direction_match = -1.01
	var top_ability:Ability
	for a in _ability_wheel_manager_handle._all_abilities:
		var ability_dir = _bottle_center.global_position.direction_to(a.global_position)
		var bottle_dir = Vector2.from_angle(_button_handle.rotation)
		var d_p = bottle_dir.dot(ability_dir)
		if (d_p > top_direction_match):
			top_ability = a
			top_direction_match = d_p
	
	if (top_ability):
		var goal_dir = _bottle_center.global_position.direction_to(top_ability.global_position)
		_button_handle.rotation = deg_to_rad(fmod(rad_to_deg(_button_handle.rotation),360.0))
		
		var rotation_delta = rad_to_deg(_button_handle.rotation - goal_dir.angle())
		var goal_angle = rad_to_deg(goal_dir.angle())
		#if (goal_angle < 0) :
		#	goal_angle += 360.0
			
			
		print_rich("[color=RED] FOUND ABILITY AT: "+str(top_ability.name)+"- Rotation off by: "+str(rotation_delta)+" Rotation: "+str(rad_to_deg(_button_handle.rotation))+" - "+str(rad_to_deg(goal_dir.angle())))
		await SimonTween.start_tween(_button_handle,"rotation",deg_to_rad(goal_angle),0.6).set_slerp(true).tween_finished
		SimonTween.start_tween(_button_handle,"scale",Vector2(0.2,0.2),0.5,_shake_curve).set_relative(true)
		top_ability.bright_flash()
		G.popup_text.emit(top_ability._ability_name,top_ability.global_position)
		await SimonTween.start_tween(top_ability,"scale",Vector2(1.2,1.2),0.5,_shake_curve).set_relative(true).tween_finished
		
		
		var mag = top_ability.get_magnitude()
		await top_ability.damage_numbers_popup()
		SimonTween.start_tween(_combo_counter_handle,"scale",Vector2(-0.5,-0.5),0.4,_strike_curve).set_relative(true)
		await SimonTween.start_tween(_combo_counter_handle,"global_position",top_ability.global_position-_combo_counter_handle.global_position-(_combo_counter_handle.size/2),0.4,_strike_curve).set_relative(true).tween_finished
		_combo_counter_handle.modulate.a = 0
		top_ability.set_magnitude(mag * _combo_number)
		await top_ability.damage_numbers_update(top_ability.get_magnitude())
		
		if (rotation_delta < 5):
			await SimonTween.start_tween(_crit_handle,"modulate:a",1.0,0.1).tween_finished
			SimonTween.start_tween(_crit_handle,"scale",Vector2(-0.5,-0.5),0.4,_strike_curve).set_relative(true)
			await SimonTween.start_tween(_crit_handle,"global_position",top_ability.global_position-_crit_handle.global_position-(_crit_handle.size/2),0.4,_strike_curve).set_relative(true).tween_finished
			_crit_handle.modulate.a = 0
			top_ability.set_magnitude(top_ability.get_magnitude() * 2)
			await top_ability.damage_numbers_update(top_ability.get_magnitude())
		
		await top_ability.damage_numbers_go_down()
		SimonTween.start_tween(_combo_handle,"modulate:a",0.0,0.5)
		#G.execute_ability.emit(top_ability,_combo_number,true)
		_gm_handle._player_manager_handle.execute_ability(top_ability,top_ability.get_magnitude(),true)
		top_ability.reset_magnitude()
		#if (!continue_round):
		if (_gm_handle._player_manager_handle.is_player_alive() and _gm_handle._player_manager_handle.is_enemy_alive()):
			change_state(BottleStatus.ENEMY_TURN)
				
				
func shrink_charge_value():
	SimonTween.start_tween(_charging_label,"scale",Vector2.ZERO,0.3)
				
func setup_enemy_spin():
	_enemy_spin_time_target = randf_range(_enemy_initial_spin_time.x,_enemy_initial_spin_time.y)
	_enemy_spin_time = 0.0
				
func process_enemy(delta):
	_enemy_spin_force = _enemy_spin_falloff.sample(_enemy_spin_time/_enemy_spin_time_target)
	_enemy_button_handle.rotation += deg_to_rad(_enemy_spin_force) * delta
	_enemy_spin_time += delta
	# = 
	
	if (_enemy_spin_time > _enemy_spin_time_target):
		eval_enemy()
				
func eval_enemy():
	change_state(BottleStatus.IN_PROGRESS)
	
	var top_ability:Ability
	var top_direction_match:float = -1.01
	#_enemy_button_handle.rotation = deg_to_rad(randf_range(0,360))
	for a in _ability_wheel_manager_handle._all_enemy_abilities:
		var ability_dir = _enemy_bottle_center.global_position.direction_to(a.global_position)
		var bottle_dir = Vector2.from_angle(_enemy_button_handle.rotation)
		var d_p = bottle_dir.dot(ability_dir)
		if (d_p > top_direction_match):
			top_ability = a
			top_direction_match = d_p

	if (top_ability):	
		var goal_dir = _enemy_bottle_center.global_position.direction_to(top_ability.global_position)
		#_enemy_button_handle.rotation = deg_to_rad(fmod(rad_to_deg(_enemy_button_handle.rotation),360.0))
		
		var goal_angle = rad_to_deg(goal_dir.angle())
		await SimonTween.start_tween(_enemy_button_handle,"rotation",deg_to_rad(goal_angle),0.4).set_slerp(true).tween_finished
		await top_ability.damage_numbers_popup()
		await top_ability.damage_numbers_go_down()
		G.execute_ability.emit(top_ability,1,false)
		change_state(BottleStatus.IDLE)
						
func flash_bottle():
	SimonTween.start_tween(_bottle_flash_handle,"modulate:a",0.5,1.0,_bottle_flash_curve).set_relative(true)
						
func reset_combo():
	_combo_number = 0
	if (_combo_handle.modulate.a > 0):
		await SimonTween.start_tween(_combo_handle,"modulate:a",0.0,0.3).tween_finished
		
	if _crit_handle.modulate.a > 0:
		SimonTween.start_tween(_crit_handle,"modulate:a",0.0,0.3)
	_combo_counter_handle.text = ""
	_combo_counter_handle.position = Vector2(0,0)
	_combo_counter_handle.scale = Vector2(1,1)
	_combo_counter_handle.modulate.a = 1
	_crit_handle.position = Vector2(0,0)
	_crit_handle.scale = Vector2(1,1)
	_combo_handle.global_position = _all_bottle_handle.global_position - (_combo_handle.size/2)
