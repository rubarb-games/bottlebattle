class_name BottleManager extends Control

enum BottleStatus { IDLE, SPINNING, INACTIVE, IN_PROGRESS, EVALUATING }
var _status:BottleStatus = BottleStatus.INACTIVE

@export var _ability_wheel_manager_handle:AbilityWheelManager
@export var _game_manager_handle:GameManager

@export var _button_handle: Button
@export var _bottle_center:Marker2D

@export var _spin_curve:Curve
@export var _shake_curve:Curve
@export var _spin_falloff_curve:Curve
@export var _mouse_velocity_curve:Curve

@export var _status_label:Label
@export var _debug_handle_a: Label
@export var _debug_handle_b: Label
@export var _debug_handle_c: Label

@export var ability_arr:Array[ColorRect]
var target_ability:ColorRect

@export var _distance_curve_falloff:Curve

var _combo_number: int = 0
var _total_degrees_spun: float = 0.0
@export var _combo_counter_handle:Label

var _initial_spin_velocity:float = 0.0
var _spinning_timer:float = 0.0
@export var _spinning_timer_max:float = 1.5

var _main_click_pressed: bool = false
var _secondary_click_pressed: bool = false

var _last_mouse_position: Vector2 = Vector2.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO

var _mouse_speed_buildup: Vector2 = Vector2.ZERO

var _mouse_speed_multiplier: float = 1000.0
var _bottle_rotation_multiplier: float = 1.0

var _bottle_angular_velocity:float = 0.0

var _bottle_angular_velocity_treshold:float = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	reset_values()
	
	#change_state(BottleStatus.IDLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (_game_manager_handle._player_status != GameManager.PlayerStatus.IDLE \
	or _game_manager_handle._round_status != GameManager.RoundStatus.GAMEPLAY):
		return
	
	match _status:
		BottleStatus.IDLE:
			#check_rotation()
			get_input(delta)
			calculate_bottle_rotation(delta)
		BottleStatus.SPINNING:
			spin_bottle(delta)
			check_spinning()
		BottleStatus.IN_PROGRESS:
			pass
		BottleStatus.INACTIVE:
			pass
		BottleStatus.EVALUATING:
			pass

func get_input(delta):
	if (Input.is_action_just_pressed("main_click")):
		_main_click_pressed = true
	elif (Input.is_action_just_released("main_click")):
		_main_click_pressed = false
		check_rotation()
		
	if (Input.is_action_just_pressed("right_click")):
		_secondary_click_pressed = true
	elif (Input.is_action_just_released("right_click")):
		_secondary_click_pressed = false
	
	var mouse_position = get_global_mouse_position()
	_mouse_delta = mouse_position - _last_mouse_position
	_last_mouse_position = mouse_position

	if (_main_click_pressed):
		_mouse_speed_buildup += _mouse_delta * delta * _mouse_speed_multiplier
		#Dampen speed buildup over time
	_mouse_speed_buildup = lerp(_mouse_speed_buildup,Vector2.ZERO,delta * 2)
	_debug_handle_a.text = "Mouse speed: "+str(Vector2(roundf(_mouse_speed_buildup.x*100)/100,roundf(_mouse_speed_buildup.y*100)/100))

func change_state(state:BottleStatus):
	match state:
		BottleStatus.IDLE:
			_status_label.text = "BOTTLE IS IDLE!"
			reset_values()
			_status = state
		BottleStatus.SPINNING:
			_status_label.text = "BOTTLE IS SPINNING!"
			_spinning_timer = 0.0
			_total_degrees_spun = 0.0
			_initial_spin_velocity = _bottle_angular_velocity 
			_status = state
		BottleStatus.IN_PROGRESS:
			_status = state
		BottleStatus.INACTIVE:
			_status = state
		BottleStatus.EVALUATING:
			_status_label.text = "BOTTLE IS EVALUATING!"
			eval_direction()
			_status = state

func start_gameplay_round():
	change_state(BottleStatus.IDLE)
	
func end_gameplay_round():
	change_state(BottleStatus.INACTIVE)

func reset_values():
	_combo_counter_handle.text = ""
	_combo_number = 0
	
	_mouse_speed_buildup = Vector2.ZERO
	_bottle_angular_velocity = 0.0
	_last_mouse_position = get_global_mouse_position()
	_main_click_pressed = false

func check_rotation():
	if (_bottle_angular_velocity >= _bottle_angular_velocity_treshold):
		change_state(BottleStatus.SPINNING)

func check_spinning():
	if (_bottle_angular_velocity <= 0.05):
		change_state(BottleStatus.EVALUATING)

func calculate_bottle_rotation(delta):
	#get direction from angle
	var bottle_dir:Vector2 = Vector2.RIGHT.rotated( _bottle_center.rotation) 
	var bottle_cross = _spin_curve.sample(bottle_dir.dot(_mouse_speed_buildup))
	
	var max_axis
	if (_mouse_speed_buildup.normalized().abs().x >= _mouse_speed_buildup.normalized().abs().y): 
		max_axis = _mouse_speed_buildup.normalized().x
	else:
		max_axis = _mouse_speed_buildup.normalized().y * -1
	max_axis *= -1
	bottle_cross = _spin_curve.sample(max_axis)
	
	#Get mouse relative to center
	var mouse_pos = get_global_mouse_position()
	var distance:Vector2 =  _bottle_center.global_position - mouse_pos
	var dir:Vector2 = distance.normalized()
	dir = dir.rotated(deg_to_rad(-90))
	var speedEval = _spin_curve.sample(dir.dot(_mouse_speed_buildup.normalized()))
	#speedEval = lerp(speedEval,max_axis,_distance_curve_falloff.sample(distance.length()))
	
	#_bottle_angular_velocity += deg_to_rad(bottle_cross * _bottle_rotation_multiplier * _mouse_speed_buildup.length() * delta)
	_bottle_angular_velocity += deg_to_rad(speedEval * _bottle_rotation_multiplier * _mouse_speed_buildup.length() * delta)
	_bottle_angular_velocity = clamp(lerp(_bottle_angular_velocity,0.0,delta*0.1),-_bottle_angular_velocity_treshold*10, _bottle_angular_velocity_treshold*10)
	
	_button_handle.rotation += _bottle_angular_velocity * delta# * _bottle_rotation_multiplier
	_debug_handle_b.text = "Bottle cross value: "+str(roundf(_bottle_angular_velocity*100)/100)
	if (_bottle_angular_velocity > _bottle_angular_velocity_treshold):
		_button_handle.modulate.b = 0.5
	else:
		_button_handle.modulate.b = 1.0

func spin_bottle(delta):
	_spinning_timer += delta
	_bottle_angular_velocity = clamp(lerp(_initial_spin_velocity,0.0,_spin_falloff_curve.sample(_spinning_timer)),-50, 50)
	_button_handle.rotation += _bottle_angular_velocity * delta
	
	_total_degrees_spun += rad_to_deg(_bottle_angular_velocity * delta)
	if (_total_degrees_spun > 360.0):
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
		if (goal_angle < 0) :
			goal_angle += 360.0
		
		if (rotation_delta < 5):
			G.popup_text.emit("CRITICAL HIT!",top_ability.global_position)
			_combo_number *= 2
			_combo_counter_handle.text = str(_combo_number)+"x"
			
		print_rich("[color=RED] FOUND ABILITY AT: "+str(top_ability.name)+"- Rotation off by: "+str(rotation_delta)+" Rotation: "+str(rad_to_deg(_button_handle.rotation))+" - "+str(rad_to_deg(goal_dir.angle())))
		await SimonTween.start_tween(_button_handle,"rotation",deg_to_rad(goal_angle),0.6).tween_finished
		SimonTween.start_tween(_button_handle,"scale",Vector2(0.2,0.2),0.5,_shake_curve).set_relative(true)
		G.popup_text.emit(top_ability._ability_name,top_ability.global_position)
		await SimonTween.start_tween(top_ability,"scale",Vector2(1.2,1.2),0.5,_shake_curve).set_relative(true).tween_finished
		
		G.execute_ability.emit(top_ability._data,_combo_number)
		
		change_state(BottleStatus.IDLE)
				
