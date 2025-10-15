class_name BottleManager extends Control

enum BottleStatus { IDLE, CHARGING, SPINNING, INACTIVE, IN_PROGRESS, EVALUATING, ENEMY_TURN }
var _status:BottleStatus = BottleStatus.INACTIVE

@export var _ability_wheel_manager_handle:AbilityWheelManager
@export var _gm_handle:GameManager

@export var _default_bottle:Bottle
var _bottle_data:Bottle

@export var _button_handle: Button
@export var _bottle_center:Marker2D
@export var _bottle_spin_eval_position:Marker2D
@export var _bottle_status_label:Label
@export var _all_bottle_handle:Control
@export var _bottle_sprite:Sprite2D
@export var _all_bottle_area_handle:Control

@export var adjacency_line_handle:Line2D
var line_end_position:Vector2 = Vector2.ZERO

@export var _all_bottles_handle:Control

@export var _all_enemy_bottle_handle:Control
@export var _enemy_bottle_center:Marker2D
@export var _enemy_button_handle:Button
@export var _enemy_bottle_sprite:Sprite2D
var _enemy_initial_spin_time:Vector2 = Vector2(0.5,1.2)
var _enemy_spin_time_target:float = 0.0
var _enemy_spin_time:float = 0.0
var _enemy_spin_force:float = 0.0
var _bottle_spin_positive:int = 1
var _enemy_bottle_data:Bottle
@export var _enemy_bottle_arc_visuals:Sprite2D

@export var _bottle_arc_visuals_handle:Sprite2D
@export var _bottle_arc_range:float = 10.0
@export var _bottle_crit_range:float = 5.0
@export var _bottle_max_abilities:int = 3

@export var _bottle_crit_multiplier:float = 5.0

@export var _bottle_arc_alpha:float = 0.0
@export var _arc_fading_in:bool = false

var _speed_charging_treshold_base:float = 20.0
var _speed_charging_treshold:float = 18.0
var _speed_treshold:float = 50.0
var _time_between_rounds:float = 0.5

var _dragged_bottle:BottleLoot
var _dragging_ability:bool = false
var _initial_drag_position:Vector2

@export var _spin_curve:Curve
@export var _shake_curve:Curve
@export var _speed_buildup_falloff_curve:Curve
@export var _spin_falloff_curve:Curve
@export var _mouse_velocity_curve:Curve
@export var _strike_curve:Curve
@export var _distance_curve_falloff:Curve
@export var _enemy_spin_falloff:Curve
@export var _bottle_flash_curve:Curve
@export var _adjacency_curve:Curve

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
var _hovering_over_bottle:bool = false
var _bottle_over_charging_treshold_speed = false

var _grab_position:Vector2
var _last_mouse_position: Vector2 = Vector2.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var _mouse_dampen_multipler:float = 5.0
var _mouse_speed_buildup: Vector2 = Vector2.ZERO

@export var _mouse_speed_multiplier: float = 2000.0

var _bottle_rotation_multiplier: float = 6.0
var _bottle_dampen_multiplier: float = 3.0
var _bottle_angular_velocity:float = 0.0
var _bottle_angular_velocity_treshold:float = 1.25

var _app_in_focus:bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	#_button_handle.mouse_entered.connect(on_mouse_entered)
	#_button_handle.mouse_exited.connect(on_mouse_exited)
	#Register class
	G.register_manager.emit(self)
	
	G.start_encounter.connect(on_encounter_start)
	
	G.dragging_bottle.connect(on_drag_bottle)
	G.stop_dragging_bottle.connect(on_stop_drag_bottle)
	
	G.flash_bottle.connect(on_flash_bottle)
	G.flash_bottle_green.connect(on_flash_bottle_green)
	
	initial_reset_values()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	do_dragging(delta)
	
	fade_arc_visuals(delta)
	adjacency_line_handle.points[1] = line_end_position
	
	if (GameManager.Main.get_player()._player_status != PlayerManager.PlayerStatus.IDLE \
	or GameManager.Main._round_status != GameManager.RoundStatus.GAMEPLAY):
		return
	
	match _status:
		BottleStatus.IDLE:
			#check_rotation()
			get_input_idle(delta)
			arc_fade_when_close()
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
	if ((get_global_mouse_position().distance_to(_bottle_center.global_position) < 100.0)):
		if (!_hovering_over_bottle):
			G.cursor_active.emit()
		_hovering_over_bottle = true
	else:
		if _hovering_over_bottle:
			G.cursor_inactive.emit()
		_hovering_over_bottle = false
	
	if (Input.is_action_just_pressed("main_click") and _hovering_over_bottle):
		_mouse_speed_buildup = Vector2.ZERO
		#_main_click_pressed = get_input_inside_bb(get_global_mouse_position(),_button_handle.global_position.x,_button_handle.global_position.y,_button_handle.size.x,_button_handle.size.y)
		_main_click_pressed = true
		_grab_position = get_global_mouse_position()
		G.cursor_grab_sprite.emit()
	elif (Input.is_action_just_released("main_click")):
		G.cursor_active_sprite.emit()
		pass
		#_main_click_pressed = false
		#check_rotation()
		
	if (Input.is_action_just_pressed("right_click")):
		_secondary_click_pressed = true
	elif (Input.is_action_just_released("right_click")):
		_secondary_click_pressed = false

	if !_app_in_focus or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or \
	abs(get_global_mouse_position().length()) > get_viewport().size.x*1.5:
		_main_click_pressed = false
		#_secondary_click_pressed = false
	_debug_handle_b.text = str(get_global_mouse_position())
	get_mouse_delta(_main_click_pressed, delta)
		
func get_input_inside_bb(pos:Vector2,x:float,y:float,w:float,h:float):
	if (\
	pos.x > x and pos.x < x + w \
	and pos.y > y and pos.y < y + h \
	):
		return true
	return false
	
func get_input_idle(delta):
	get_input(delta)

func get_input_charging(delta):
	get_input(delta)
	var _relative_mouse_mag = Vector2( _grab_position - _bottle_center.global_position).length()
	var _actual_mouse_mag =  Vector2(get_global_mouse_position() - _bottle_center.global_position).length()
	var _mouse_pos_adjusted = Vector2(get_global_mouse_position() - _bottle_center.global_position).normalized() * _relative_mouse_mag + _bottle_center.global_position
	
	G.cursor_override_position.emit(_mouse_pos_adjusted)

func _notification(what: int):
	if what == NOTIFICATION_FOCUS_EXIT:
		_app_in_focus = false
	if what == NOTIFICATION_FOCUS_ENTER:
		_app_in_focus = true
		

func check_charging_state():
	if (abs(_bottle_angular_velocity) > _speed_charging_treshold):
		if (!_bottle_over_charging_treshold_speed):
			G.cursor_set_green.emit()
		_bottle_over_charging_treshold_speed = true
		change_state(BottleStatus.SPINNING)
	else:
		if (_bottle_over_charging_treshold_speed):
			G.cursor_set_white.emit()
		_bottle_over_charging_treshold_speed = false

	if (!_main_click_pressed and _bottle_over_charging_treshold_speed):
		change_state(BottleStatus.SPINNING)
		
	if (!_main_click_pressed and !_bottle_over_charging_treshold_speed):
		change_state(BottleStatus.IDLE)
	
func check_idle_state():
	if (_main_click_pressed and abs(_bottle_angular_velocity) > _speed_charging_treshold):
		change_state(BottleStatus.CHARGING)

func change_state(state:BottleStatus):
	match state:
		BottleStatus.IDLE:
			#NEXT TURN STARTED!
			G.next_turn_started.emit()
			flash_bottle()
			_speed_charging_treshold = _speed_charging_treshold_base + randf_range(-4.0,4.0)
			SimonTween.start_tween(_all_bottle_handle,"modulate",Color.WHITE,G.anim_speed_slow)
			#_status_label.text = "BOTTLE IS IDLE!"
			reset_values()
			shrink_charge_value()
			G.popup_round_timer_text.emit("Click and drag to spin!")
			_status = state
		BottleStatus.CHARGING:
			SimonTween.start_tween(_all_bottle_handle,"modulate",Color.WHITE,G.anim_speed_slow)
			flash_bottle()
			G.popup_round_timer_text.emit("Charging!!!")
			#_status_label.text = "CHARGING!"
			_status = state
		BottleStatus.SPINNING:
			flash_bottle()
			G.cursor_set_white.emit()
			G.cursor_active_sprite.emit()
			G.cursor_resume_position.emit()
			SimonTween.start_tween(_charging_label,"scale",Vector2(1,1),G.anim_speed_slow*6,null)
			SimonTween.start_tween(_charging_label,"modulate:a",0.0,G.anim_speed_slow*6,null)
			G.popup_round_timer_text.emit("Spinning!")
			#_status_label.text = "SPINNING!"
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
			#_status_label.text = "BOTTLE IS EVALUATING!"
			_bottle_over_charging_treshold_speed = false
			shrink_charge_value()
			eval_direction()
			_status = state
		BottleStatus.ENEMY_TURN:
			await get_tree().create_timer(_time_between_rounds).timeout
			_status = state
			setup_enemy_spin()
			G.popup_round_timer_text.emit("Enemy turn!")
			#_status_label.text = "ENEMY TURN!"

func start_gameplay_round():
	change_state(BottleStatus.IDLE)
	
func end_gameplay_round():
	change_state(BottleStatus.INACTIVE)

func initial_reset_values():
	_bottle_status_label.modulate.a = 0.0
	_bottle_data = _default_bottle
	apply_bottle(_bottle_data)
	#fade_arc_visuals(false)
	reset_values()

func reset_values():
	reset_combo()
	
	_bottle_flash_handle.modulate.a = 0
	_mouse_speed_buildup = Vector2.ZERO
	_bottle_angular_velocity = 0.0
	_last_mouse_position = get_global_mouse_position()
	_main_click_pressed = false
	_charging_label.modulate.a = 1.0
	_charging_label.scale = Vector2.ZERO
	#_bottle_arc_visuals_handle.modulate.a = 0.0

func check_rotation():
	if (_bottle_angular_velocity >= _bottle_angular_velocity_treshold):
		change_state(BottleStatus.SPINNING)

func check_spinning():
	if (abs(_bottle_angular_velocity) <= 0.05):
		change_state(BottleStatus.EVALUATING)

func calculate_bottle_rotation(delta):
	#get direction from angle
	var bottle_dir:Vector2 = Vector2.RIGHT.rotated( _bottle_center.rotation) 

	#Get mouse relative to center
	var mouse_pos = get_global_mouse_position()
	var distance:Vector2 =  _bottle_center.global_position - mouse_pos
	var dir:Vector2 = distance.normalized()
	dir = dir.rotated(deg_to_rad(-90))
	var speedEval = _spin_curve.sample(dir.dot(_mouse_speed_buildup.normalized()))
	#REVISE THIS WITH SOMETHING BETTER!!!
	var tempMultiplier = _bottle_rotation_multiplier# * (1 - _speed_buildup_falloff_curve.sample(abs(_bottle_angular_velocity) / _speed_treshold))
	var tempVelocity = deg_to_rad(speedEval * tempMultiplier * _mouse_speed_buildup.length())
	
	_bottle_angular_velocity = lerp(_bottle_angular_velocity,_bottle_angular_velocity+tempVelocity, delta)
	
	if !Input.is_action_pressed("main_click"):
		dampen_bottle_spin(delta*15)
	else:
		dampen_bottle_spin(delta)

	_button_handle.rotation +=  _bottle_angular_velocity * delta# * _bottle_rotation_multiplier
	
func dampen_bottle_spin(delta):
	#THIS JUST DAMPENS THE ANGULAR VELOCITY
	if (_bottle_angular_velocity >= 0):
		_bottle_angular_velocity = clamp(_bottle_angular_velocity - (delta * _bottle_dampen_multiplier),0,_speed_treshold)
	else:
		_bottle_angular_velocity = clamp(_bottle_angular_velocity + (delta * _bottle_dampen_multiplier),-_speed_treshold,0)
	
func get_mouse_delta(is_mouse_clicked:bool, delta):
	var mouse_position = get_global_mouse_position()
	_mouse_delta = mouse_position - _last_mouse_position
	_last_mouse_position = mouse_position
	
	if (is_mouse_clicked):
		var mouse_force = _mouse_speed_buildup.length()
		#_mouse_delta * delta * _mouse_speed_multiplier
		_mouse_speed_buildup += (_mouse_delta * delta * _mouse_speed_multiplier) * _mouse_velocity_curve.sample(_mouse_delta.length()/200.0)
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
	
	_total_degrees_spun += abs(rad_to_deg(_bottle_angular_velocity * delta))
	if (_total_degrees_spun > 360.0):
		if (_combo_handle.modulate.a < 1):
			#print("HELL YEAH; MORE COMMMMB")
			SimonTween.start_tween(_combo_handle,"modulate:a",1.0,G.anim_speed_fast)
		_total_degrees_spun -= 360
		_combo_number += 1
		_combo_counter_handle.text = str(_combo_number)+"+ \n SPINS!"
		SimonTween.start_tween(_combo_counter_handle,"scale",Vector2(0.2,0.2),G.anim_speed_fast,_shake_curve).set_relative(true)

func eval_direction():
	var top_direction_match = -1.01
	var top_ability:Ability
	var abilities_in_range:Array = []

	SimonTween.start_tween(_combo_handle,"scale",Vector2(-0.33,-0.33),G.anim_speed_slow,null).set_relative(true)
	await SimonTween.start_tween(_combo_handle,"global_position",_bottle_spin_eval_position.global_position,G.anim_speed_slow,null).tween_finished 
	start_arc_fade(true)
	flash_bottle()
	#await SimonTween.start_tween(_bottle_arc_visuals_handle,"modulate:a",1.0,1.0,null).set_relative(true).tween_finished
	
	for a in _ability_wheel_manager_handle._all_abilities:
		a.adjacency_radius_green_off()
		a.hide_green_highlight()
		
		var ability_dir = _bottle_center.global_position.direction_to(a.global_position)
		print("Ability "+str(a.name)+" IS :"+str(rad_to_deg(ability_dir.angle())))
		var bottle_dir = fmod(rad_to_deg(_button_handle.rotation),360.0)
		var a_angle = rad_to_deg(ability_dir.angle())
		var angle_diff = calc_angle_between(bottle_dir,a_angle)
		
		a.set_distance_to_hit(angle_diff)
		if (abs(angle_diff) < (_bottle_arc_range/2.0)):
			#a.popup_ability_name()
			#G.popup_text.emit(a._ability_name,a.global_position)
			#SimonTween.start_tween(_button_handle,"scale",Vector2(0.05,0.05),G.anim_speed_medium,_shake_curve).set_relative(true)
			#await SimonTween.start_tween(a,"scale",Vector2(1.2,1.2),0.5,_shake_curve).set_relative(true).tween_finished
			#await a.bright_flash()	
			abilities_in_range.append(a)
			
	#await get_tree().create_timer(0.5).timeout
			
	#EXECUTE ABILITIES!
	var ability_magnitude:float = 0.0
	var current_mag:int = 0
	var break_loop:bool = false
	
	if (abilities_in_range.size() > 0):
		#HIT!
		var ab:Ability
		var last_in_chain:bool = false
		#Set critical hit if there's only ONE ability hit
		var is_crit:bool = false
		
		#Sort to prioritize non-enemy abilities
		abilities_in_range.sort_custom(func(a:Ability, b:Ability): \
		if (b._data._ability_type == AbilityData.Type.WHEEL_DEBUFF):
			return true
		else:
			return false
		)
		
		#Loop thorugh all abilities in range, max being determined by the bottle
		for i in range(clamp(abilities_in_range.size(),0,_bottle_data.max_bottle_abilities)):
			ab = abilities_in_range[i]
			ability_magnitude = 0.0
			if (i >= (abilities_in_range.size() - 1)):
				last_in_chain = true
				
				
			current_mag = await evaluate_single_ability(ab,last_in_chain, true, true, true, is_crit)
			ability_magnitude += current_mag
			
			#EXECUTE THE ABILITY
			if (ability_magnitude <= 0):
				#popup_status("No effect")
				continue
			
			await _gm_handle._player_manager_handle.execute_ability(ab,ability_magnitude,true)
			if (!_gm_handle._player_manager_handle.is_player_alive() or !_gm_handle._player_manager_handle.is_enemy_alive()):
				#break
				return
	else:
		#MISS!
		popup_status("Missed!!!")
		await get_tree().create_timer(0.75).timeout
	
	#SimonTween.start_tween(_bottle_arc_visuals_handle,"modulate:a",-1.0,1.5,null).set_end_snap(true)
	start_arc_fade(false)
	reset_combo()
	
	change_state(BottleStatus.ENEMY_TURN)
	return
				
func apply_bottle(b:Bottle):
	_bottle_arc_range = b.arc_range
	_bottle_crit_multiplier = b.crit_multiplier
	_bottle_crit_range = b.crit_range
	_bottle_sprite.texture = b.bottle_texture
	
	_bottle_arc_visuals_handle.material.set_shader_parameter("progress",_bottle_arc_range/360)
	_bottle_arc_visuals_handle.material.set_shader_parameter("progress_2",_bottle_crit_range/360)
	_bottle_arc_visuals_handle.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,0.0))
	
	flash_bottle()
	SimonTween.start_tween(_button_handle,"scale",Vector2(0.05,0.05),G.anim_speed_medium,_shake_curve).set_relative(true)
	
				
func popup_status(txt:String):
	var y = 50
	
	_bottle_status_label.text = txt
	_bottle_status_label.modulate.a = 0.0
	_bottle_status_label.position.y = y
	SimonTween.start_tween(_bottle_status_label,"modulate:a",1.0,G.anim_speed_medium,null)
	await SimonTween.start_tween(_bottle_status_label,"position:y",y * -1,G.anim_speed_medium,null).set_relative(true).tween_finished
	
	await get_tree().create_timer(0.5).timeout

	SimonTween.start_tween(_bottle_status_label,"modulate:a",0.0,G.anim_speed_medium,null)
	await SimonTween.start_tween(_bottle_status_label,"position:y",y,G.anim_speed_medium,null).set_relative(true).tween_finished
	_bottle_status_label.position.y = 0.0
				
func calc_angle_between(a:float, b:float):
	var angle = abs(a - b)
	if (angle > 180.0):
		return 360.0 - angle
	return angle
				
func evaluate_single_ability(ab:Ability, last_in_chain:bool = false, involve_combos:bool = false, involve_crits:bool = false, is_player:bool = true, is_crit:bool = false) -> float:
	await get_tree().create_timer(G.anim_speed_fast).timeout
	print_rich("[color=AQUA]Executing ability: "+str(ab._ability_name)+" - Distance is: "+str(ab.get_distance_to_hit()))
	var anim_time:float = G.anim_speed_fast
	
	#ab.bright_flash()
	#G.popup_text.emit(ab._ability_name,ab.global_position)
	ab.popup_ability_name()
	ab.show_green_highlight()
	await get_tree().create_timer(G.anim_speed_medium).timeout
	
	var mag:int = ab.get_magnitude()
	
	if (mag <= 0):
		G.popup_text.emit("No effect",ab.global_position)
		return mag
	
	if (ab._data._ability_type == AbilityData.Type.BUFF or ab._data._ability_type == AbilityData.Type.DEBUFF):
		ab.lower_ability_name()
		ab.damage_numbers_go_down()
		ab.hide_green_highlight()
		return mag
	
	await ab.damage_numbers_popup(mag)
	
	mag += await _gm_handle._player_manager_handle.evaluate_all_buffs(mag,ab,is_player)
	
	
	#Get adjacency bonuses
	if !ab.is_enemy():
		for b in _ability_wheel_manager_handle._all_abilities:
			if b == ab:
				continue
				
			if ab.global_position.distance_to(b.global_position) < b._data._ability_adjacency_range/2:
				b.bright_flash()
				#b.adjacency_radius_green_on()
				var in_pos:Vector2 = b.global_position
				match b._data._ability_adjacency_type:
					AbilityData.AdjacencyType.EXTRA_DAMAGE:
						b.popup_status_text("[color=GREEN]Damage boost")
						#await SimonTween.start_tween(b,"global_position",ab.global_position - b.global_position,G.anim_speed_fast).set_relative(true).tween_finished
						await b.line_to_location(ab.global_position)
						await ab.bright_flash()
						b.reset_line()
						b.global_position = in_pos
						#SimonTween.start_tween(b,"global_position",b.global_position-in_pos,G.anim_speed_fast).set_relative(true)
						#await get_tree().create_timer(G.anim_speed_medium).timeout
						b.global_position = in_pos
						#b.adjacency_radius_green_off()
						ab.damage_numbers_update(b._data._ability_adjacency_mag,"GREEN")
						mag += b._data._ability_adjacency_mag
					AbilityData.AdjacencyType.DESTROY_DEBUFF:
						if ab._data._ability_type == AbilityData.Type.WHEEL_DEBUFF:
							b.popup_status_text("[color=GREEN]Destroy debuffs")
							await SimonTween.start_tween(b,"global_position",ab.global_position - b.global_position,G.anim_speed_fast).set_relative(true).tween_finished
							await ab.bright_flash()
							#await get_tree().create_timer(G.anim_speed_medium).timeout
							b.global_position = in_pos
							#b.adjacency_radius_green_off()
							ab.destroy()
							return false
					AbilityData.AdjacencyType.HEAL:
						_gm_handle._player_manager_handle.adjust_player_health(b._data._ability_adjacency_mag,PlayerManager.Op.PLUS)
						b.popup_status_text("[color=GREEN]Heal!")
						await b.line_to_location(ab.global_position)
						await ab.bright_flash()
						b.reset_line()
						#await get_tree().create_timer(G.anim_speed_medium).timeout
						b.global_position = in_pos
						#b.adjacency_radius_green_off()
	# Apply combo
	if (involve_combos):
		SimonTween.start_tween(_combo_counter_handle,"scale",Vector2(-0.5,-0.5),anim_time,_strike_curve).set_relative(true)
		await SimonTween.start_tween(_combo_counter_handle,"global_position",ab.global_position-_combo_counter_handle.global_position-(_combo_counter_handle.size/2),anim_time,_strike_curve).set_relative(true).tween_finished
		_combo_counter_handle.modulate.a = 0
		
		#Actually apply the combo stats
		mag += _combo_number
		await ab.damage_numbers_update(_combo_number,"GOLD")
	
	if (ab.get_distance_to_hit() < _bottle_crit_range and involve_crits):
	#if (is_crit):
		#Handling critical hits
		#SimonTween.start_tween(_crit_handle,"scale",Vector2(1.4,1.4),G.anim_speed_medium,_shake_curve).set_relative(true)
		#await SimonTween.start_tween(_crit_handle,"modulate:a",1.0,G.anim_speed_medium).tween_finished
		#SimonTween.start_tween(_crit_handle,"scale",Vector2(-0.5,-0.5),anim_time,_strike_curve).set_relative(true)
		#await SimonTween.start_tween(_crit_handle,"global_position",ab.global_position-_crit_handle.global_position-(_crit_handle.size/2),anim_time,_strike_curve).set_relative(true).tween_finished
		#_crit_handle.modulate.a = 0
		#Actually apply crit stats
		await line_to_location(_bottle_center.global_position,ab.global_position)
		await  ab.popup_status_text("[color=RED]Critical hit!")
		reset_line()
		
		var extra_crit_damage = (mag * _bottle_crit_multiplier) - mag
		mag += extra_crit_damage
		await ab.damage_numbers_update(extra_crit_damage,"RED")
	
	if (!last_in_chain):
		SimonTween.start_tween(_combo_counter_handle,"modulate:a",1.0,G.anim_speed_slow)
		_crit_handle.position = Vector2(0,0)
		_combo_counter_handle.position = Vector2(0,0)
		_combo_counter_handle.scale = Vector2(1,1)
	
	
	await get_tree().create_timer(G.anim_speed_medium).timeout
	await ab.damage_numbers_go_down()
	ab.lower_ability_name()
	ab.hide_green_highlight()
	
	return mag
				
func sort_by_distance(a:Ability, b:Ability):
	if (a.get_distance_to_hit() < b.get_distance_to_hit()):
		return true
	return false
				
func start_arc_fade(on:bool):
	if (on):
		_arc_fading_in = true
	else:
		_arc_fading_in = false
				
func arc_fade_when_close():
	if (get_global_mouse_position().distance_to(_bottle_center.global_position) < 100.0):
		start_arc_fade(true)
	else:
		start_arc_fade(false)
		
	if (get_global_mouse_position().distance_to(_enemy_bottle_arc_visuals.global_position) < 100.0):
		_enemy_bottle_arc_visuals.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,1.0))
	else:
		_enemy_bottle_arc_visuals.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,0.0))
				
func fade_arc_visuals(delta:float): 
	var c = Color.WHITE
	if (_arc_fading_in and _bottle_arc_alpha < 1.0):
		c.a = (_bottle_arc_alpha  * 0.2)
		_bottle_arc_visuals_handle.material.set_shader_parameter("tint_color",c)
		_bottle_arc_alpha  += delta * 12.0
	elif (!_arc_fading_in and _bottle_arc_alpha > 0.0):
		c.a = (_bottle_arc_alpha  * 0.2)
		_bottle_arc_visuals_handle.material.set_shader_parameter("tint_color",c)
		_bottle_arc_alpha  -= delta * 4.0
	return true
					
func shrink_charge_value():
	SimonTween.start_tween(_charging_label,"scale",Vector2.ZERO,G.anim_speed_fast)
					
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
	
	
	var abilities_in_range:Array = []
	_enemy_bottle_arc_visuals.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,1.0))
	#_enemy_button_handle.rotation = deg_to_rad(randf_range(0,360))
	for a in _ability_wheel_manager_handle._all_enemy_abilities:
		var ability_dir = _enemy_bottle_center.global_position.direction_to(a.global_position).normalized()
		var bottle_dir = fmod(rad_to_deg(_enemy_button_handle.rotation),360)
		
		var a_angle = rad_to_deg(ability_dir.angle())
		var angle_diff = calc_angle_between(bottle_dir,a_angle)
		
		a.set_distance_to_hit(angle_diff)
		if (abs(angle_diff) < (_enemy_bottle_data.arc_range / 2.0)):
			abilities_in_range.append(a)
	
	if (abilities_in_range.size() > 0):
		var ab:Ability
		var ability_magnitude:float = 0
		for i in range(abilities_in_range.size()):
			ab = abilities_in_range[i]
			ability_magnitude = 0
			
			var current_mag = await evaluate_single_ability(ab, false, false, true, false, false)
			ability_magnitude += current_mag
			_gm_handle._player_manager_handle.execute_ability(ab,ability_magnitude,false)

	_enemy_bottle_arc_visuals.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,0.0))
	change_state(BottleStatus.IDLE)
						
func flash_bottle():
	await SimonTween.start_tween(_bottle_flash_handle,"modulate:a",0.5,1.0,_bottle_flash_curve).set_relative(true).tween_finished
	return true
	
func flash_bottle_green():
	_bottle_flash_handle.color = Color.GREEN
	await flash_bottle()
	_bottle_flash_handle.color = Color.WHITE	

func on_flash_bottle():
	flash_bottle()

func on_flash_bottle_green():
	flash_bottle_green()

func update_bottle_arc_visuals():
	_bottle_arc_visuals_handle.material.set_shader_parameter("progress",_bottle_arc_range / 360.0)
	pass

func line_to_location(start_pos:Vector2,pos:Vector2):
	adjacency_line_handle.modulate.a = 0.0
	line_end_position = Vector2.ZERO
	adjacency_line_handle.points[0] = start_pos
	SimonTween.start_tween(self,"line_end_position",global_position,G.anim_speed_fast).set_relative(true)
	await SimonTween.start_tween(adjacency_line_handle,"modulate:a",1.0,G.anim_speed_fast).tween_finished
	return true
	
func reset_line():
	SimonTween.start_tween(self,"line_end_position",Vector2.ZERO,G.anim_speed_fast*2)
						
func reset_combo():
	_combo_number = 0
	if (_combo_handle.modulate.a > 0):
		await SimonTween.start_tween(_combo_handle,"modulate:a",0.0,G.anim_speed_fast).tween_finished
		
	if _crit_handle.modulate.a > 0:
		SimonTween.start_tween(_crit_handle,"modulate:a",0.0,G.anim_speed_fast)
	_combo_counter_handle.text = ""
	_combo_counter_handle.position = Vector2(0,0)
	_combo_counter_handle.scale = Vector2(1,1)
	_combo_counter_handle.modulate.a = 1
	_combo_handle.scale = Vector2.ONE
	_crit_handle.position = Vector2(0,0)
	_crit_handle.scale = Vector2(1,1)
	_combo_handle.global_position = _bottle_center.global_position - (_combo_handle.size/2)

func on_mouse_entered():
	start_arc_fade(true)
	
func on_mouse_exited():
	start_arc_fade(false)

func on_drag_bottle(b:BottleLoot):
	#print("DRAGGIN!!!!🐲🐲")
	if (!_gm_handle.is_intro_phase() and !b.is_loot()):
		return
		
	_dragged_bottle = b
	_dragging_ability = true
	_initial_drag_position = b.global_position
	flash_bottle_green()
	
func do_dragging(delta):
	if (_dragging_ability):
		var goal_position:Vector2 = _dragged_bottle.global_position
		goal_position = get_global_mouse_position()
	
		_dragged_bottle.global_position = lerp(_dragged_bottle.global_position, goal_position, delta * 20)
	
func on_stop_drag_bottle(b:BottleLoot):
	if (!is_instance_valid(_dragged_bottle)):
		return
	
	_dragging_ability = false
	
	var distance_to_bottle = b.global_position.distance_to(_bottle_center.global_position)
	if (distance_to_bottle < 100):
		_bottle_data = b._bottle_data
		await SimonTween.start_tween(b,"global_position",_bottle_center.global_position,G.anim_speed_slow,null).tween_finished
		apply_bottle(_bottle_data)
		G.add_bottle.emit(b)
		b.destroy()
	else:
		await SimonTween.start_tween(b,"global_position",_initial_drag_position,G.anim_speed_slow,null).tween_finished

func on_encounter_start():
	var enc:GameEncounters = GameManager.Main.get_encounter_manager().get_encounter_data()
	if !enc._enemy:
		return
		
	_enemy_bottle_data = enc._enemy._enemy_bottle
	_enemy_bottle_arc_visuals.material.set_shader_parameter("progress",_enemy_bottle_data.arc_range/360)
	_enemy_bottle_arc_visuals.material.set_shader_parameter("progress2",_enemy_bottle_data.crit_range/360)
	_enemy_bottle_arc_visuals.material.set_shader_parameter("tint_color",Color(1.0,1.0,1.0,0.0))
	_enemy_bottle_sprite.texture = _enemy_bottle_data.bottle_texture
