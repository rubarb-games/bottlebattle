class_name Ability extends Control

enum AbilityStatus { LOOT, ON_WHEEL, IN_INVENTORY, FREE, IDLE, ENEMY, OTHER }
var _status:AbilityStatus

var _dragging:bool = false
var _adjacency_radius:float = 250.0

var _size:float = 40.0

var _magnitude:int = 5
var _initial_magnitude:int = 0

var _initial_placement:float = -1

var line_end_position:Vector2 = Vector2.ZERO

@export var status_text_handle:RichTextLabel
var status_text_fade:bool = false
var status_text_timer:float = 0.0
var status_text_max:float = 0.4
@export var status_text_opacity_curve:Curve
@export var status_text_position_curve:Curve

var red_adjacency_fade:bool = false
var red_adjacency_timer:float = 0.0
var red_adjacency_max:float = 0.4

@export var green_adjancency_handle:Control
var green_adjacency_fade:bool = false
var green_adjacency_timer:float = 0.0
var green_adjacency_max:float = 0.15

@export var green_highlight_handle:Control
var green_highlight_fade:bool = false
var green_highlight_timer:float = 0.0
var green_highlight_max:float = 0.25

@export var adjacency_line_handle:Line2D

var bottle_distance:float = 0.0

@export var _ability_name:String
@export var _ability_description:String

@export var _ability_level:int = 1
@export var _ability_level_handle:RichTextLabel
@export var _ability_level_frame_handle:ColorRect
var _ability_fade:bool = false
var _ability_timer:float = 0.0
var _ability_timer_max:float = 0.2

@export var _ability_button_handle:Button
@export var _bright_flash:ColorRect
@export var _green_flash:ColorRect
@export var _bright_flash_curve:Curve
@export var _green_flash_curve:Curve
@export var _shake_curve:Curve
@export var _spawn_curve:Curve

@export var _adjacency_bonus_indicator:TextureRect

@export var _damage_numbers_handle:RichTextLabel
@export var _ability_name_handle:RichTextLabel
@export var _ability_sprite:Sprite2D
@export var _ability_slot_handle:ColorRect

@export var _ability_player_color:Color
@export var _ability_enemy_color:Color

var _data:AbilityData

var _wheel_placement:float = -1

var _is_highlighted = true

signal execute_ability()

# Called when the node enters the scene tree for the first time.
func _ready():
	_ability_button_handle.mouse_entered.connect(on_mouse_entered)
	_ability_button_handle.mouse_exited.connect(on_mouse_exited)
	_ability_button_handle.button_down.connect(on_ability_pressed)
	_ability_button_handle.button_up.connect(on_ability_released)
	
	initialize()

func initialize():
	execute_ability.connect(execute)
	#_adjacency_bonus_indicator.position += Vector2(20,20)
	_adjacency_bonus_indicator.modulate.a = 0
	green_adjancency_handle.modulate.a = 0
	_damage_numbers_handle.modulate.a = 0
	_initial_magnitude = _magnitude
	_adjacency_bonus_indicator.size = Vector2(50.0,200.0)
	_adjacency_bonus_indicator.position -= Vector2(100.0,100.0)
	
	_ability_level_frame_handle.modulate.a = 0.0
	_ability_name_handle.modulate.a = 0.0
	adjacency_line_handle.modulate.a = 0.0
	status_text_handle.modulate.a = 0.0
	
	self.scale = Vector2.ZERO
	SimonTween.start_tween(self,"scale",Vector2(1,1),0.5+randf_range(0.0,G.anim_speed_fast),_spawn_curve).set_relative(true)

func update_visuals_after_data(d:AbilityData):
	var range = d._ability_range * 1.5
	_adjacency_bonus_indicator.size.x = range 
	_adjacency_bonus_indicator.size.y = range
	_adjacency_bonus_indicator.position = Vector2(-range/2,-range/2)
	
	green_adjancency_handle.size.x = d._ability_adjacency_range
	green_adjancency_handle.size.y = d._ability_adjacency_range
	green_adjancency_handle.position = Vector2(-d._ability_adjacency_range/2,-d._ability_adjacency_range/2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if red_adjacency_fade and red_adjacency_timer < red_adjacency_max:
		red_adjacency_timer += delta
		_adjacency_bonus_indicator.modulate = lerp(Color(1.0,0.0,0.0,0.0),Color.RED,red_adjacency_timer/red_adjacency_max)
	elif !red_adjacency_fade and red_adjacency_timer > 0.0:
		red_adjacency_timer -= delta
		_adjacency_bonus_indicator.modulate = lerp(Color(1.0,0.0,0.0,0.0),Color.RED,red_adjacency_timer/red_adjacency_max)
		
	if green_adjacency_fade and green_adjacency_timer < green_adjacency_max:
		green_adjacency_timer += delta
		green_adjancency_handle.modulate = lerp(Color(0.0,1.0,0.0,0.0),Color.GREEN,green_adjacency_timer/green_adjacency_max)
	elif !green_adjacency_fade and green_adjacency_timer > 0.0:
		green_adjacency_timer -= delta
		green_adjancency_handle.modulate = lerp(Color(0.0,1.0,0.0,0.0),Color.GREEN,green_adjacency_timer/green_adjacency_max)
		
	if _ability_fade and _ability_timer < _ability_timer_max:
		_ability_timer += delta
		_ability_level_frame_handle.modulate.a = _ability_timer / _ability_timer_max
	elif !_ability_fade and _ability_timer > 0.0:
		_ability_timer -= delta
		_ability_level_frame_handle.modulate.a = _ability_timer / _ability_timer_max
		
	if status_text_fade and status_text_timer < status_text_max:
		status_text_timer += delta
		status_text_handle.modulate.a = status_text_opacity_curve.sample(status_text_timer / status_text_max)
		status_text_handle.position.y = status_text_position_curve.sample(status_text_timer / status_text_max) * -50
	elif !status_text_fade and status_text_timer > 0:
		status_text_timer -= delta
		status_text_handle.modulate.a = status_text_opacity_curve.sample(status_text_timer / status_text_max)
		status_text_handle.position.y = status_text_position_curve.sample(status_text_timer / status_text_max) * -50
		
	if green_highlight_fade and green_highlight_timer < green_highlight_max:
		green_highlight_timer += delta
		green_highlight_handle.modulate.a = green_highlight_timer / green_highlight_max
	elif !green_highlight_fade and green_highlight_timer > 0.0:
		green_highlight_timer -= delta
		green_highlight_handle.modulate.a = green_highlight_timer / green_highlight_max
		
	adjacency_line_handle.points[1] = line_end_position
		
func execute():
	pass

func destroy(instant:bool = false):
	if !instant:
		await SimonTween.start_tween(self,"scale",Vector2(-1,-1),0.5+randf_range(0.0,G.anim_speed_fast),_spawn_curve).set_relative(true).tween_finished
	self.queue_free()

func set_data(d:AbilityData):
	_data = d
	update_visuals_after_data(d)

func set_normal():
	_status = AbilityStatus.IDLE
	_ability_slot_handle.color = _ability_player_color
	
func set_on_wheel():
	print("Set wheel!")
	_status = AbilityStatus.ON_WHEEL
	_ability_slot_handle.color.a = 1.0

func set_loot():
	print("Set loot! LOOOT")
	_status = AbilityStatus.LOOT
	_ability_slot_handle.color.a = 0.0

func set_enemy():
	_status = AbilityStatus.ENEMY
	_ability_slot_handle.color = _ability_enemy_color

func set_dehighlight():
	_is_highlighted = false
	SimonTween.start_tween(_ability_slot_handle,"modulate",Color(0.,0.2,0.2,1),G.anim_speed_fast,null).set_end_snap(true)

func set_highlight():
	_is_highlighted = true
	SimonTween.start_tween(_ability_slot_handle,"modulate",Color(1.0,1.0,1.0,1),G.anim_speed_fast,null).set_end_snap(true)

func set_inventory():
	print("Set inventory! HEP!")
	_status = AbilityStatus.IN_INVENTORY

func set_free():
	_status = AbilityStatus.FREE

func is_loot():
	return true if _status == AbilityStatus.LOOT else false
	
func is_on_wheel():
	return true if _status == AbilityStatus.ON_WHEEL else false
	
func is_in_inventory():
	return true if _status == AbilityStatus.IN_INVENTORY else false

func is_enemy():
	return true if _status == AbilityStatus.ENEMY else false
	
func is_free():
	return true if _status == AbilityStatus.FREE else false

func bright_flash():
	await SimonTween.start_tween(_bright_flash,"modulate:a",1.0,G.anim_speed_medium,_bright_flash_curve).set_relative(true).set_start_snap(true).tween_finished
	_bright_flash.modulate.a = 0.0
	return true
	

func green_flash():
	_green_flash.scale = Vector2(0.5,0.5)
	SimonTween.start_tween(_green_flash,"modulate:a",1.0,G.anim_speed_slow,_green_flash_curve).set_relative(true).set_start_snap(true)
	await SimonTween.start_tween(_green_flash,"scale",Vector2(1.0,1.0),G.anim_speed_slow,_green_flash_curve).set_relative(true).set_end_snap(true).tween_finished
	_green_flash.scale = Vector2(1.0,1.0)
	
func get_magnitude():
	return _magnitude

func adjust_magnitude(adj:int):
	_magnitude += adj

func set_magnitude(mag:int):
	_magnitude = mag
	
func reset_magnitude():
	_magnitude = _initial_magnitude

func damage_numbers_popup(numbers:float, use_mag:bool = false):
	if use_mag:
		numbers = _magnitude
	
	_damage_numbers_handle.text = str(numbers)
	SimonTween.start_tween(_damage_numbers_handle,"modulate:a",1.0,0.25)
	await SimonTween.start_tween(_damage_numbers_handle,"position:y",-85.0, G.anim_speed_fast).tween_finished
	
	return true
	
func reset_damage_numbers():
	_damage_numbers_handle.text = ""
	
func damage_numbers_shake():
	await SimonTween.start_tween(_damage_numbers_handle,"scale",Vector2(0.5,0.5),G.anim_speed_fast,_shake_curve).set_relative(true).tween_finished
	return
	
func damage_numbers_update(num:int,c:String="BLACK"):
	_damage_numbers_handle.text += "\n[color="+c+"] +"+str(num)+"[/color]"
	await damage_numbers_shake()
	return
	
func damage_numbers_go_down():
	SimonTween.start_tween(_damage_numbers_handle,"modulate:a",0.0,0.25)
	await SimonTween.start_tween(_damage_numbers_handle,"position:y",0.0,G.anim_speed_fast).tween_finished
	
	reset_damage_numbers()
	
	return

func popup_ability_name():
	_ability_name_handle.text = _ability_name
	SimonTween.start_tween(_ability_name_handle,"modulate:a",1.0,0.25)
	await SimonTween.start_tween(_ability_name_handle,"position:y",_size*0.75,G.anim_speed_medium).tween_finished
	
	return true
	
func popup_status_text(txt:String,time:float = 0.4):
	status_text_handle.text = txt
	status_text_fade = true
	if time > 0:
		await get_tree().create_timer(time).timeout
	status_text_fade = false
	return true
	
func lower_ability_name():
	SimonTween.start_tween(_ability_name_handle,"modulate:a",0.0,0.25)
	await SimonTween.start_tween(_ability_name_handle,"position:y",_size*1.5,G.anim_speed_medium).tween_finished

func display_adjacency_radius():
	if (is_on_wheel()):
		SimonTween.start_tween(_adjacency_bonus_indicator,"modulate:a",1.0,G.anim_speed_medium).set_relative(true)
	
func hide_adjacency_radius():
	if (is_on_wheel()):
		SimonTween.start_tween(_adjacency_bonus_indicator,"modulate:a",0.0,G.anim_speed_medium)

func adjacency_radius_turn_red():
	red_adjacency_fade = true
	
func adjacency_radius_turn_white():
	red_adjacency_fade = false
	
func adjacency_radius_green_on():
	green_adjacency_fade = true
	green_adjancency_handle.modulate.a = 1.0

func adjacency_radius_green_off():
	green_adjacency_fade = false
	
func line_to_location(pos:Vector2):
	adjacency_line_handle.modulate.a = 0.0
	line_end_position = Vector2.ZERO
	SimonTween.start_tween(self,"line_end_position",pos - self.global_position,G.anim_speed_fast).set_relative(true)
	await SimonTween.start_tween(adjacency_line_handle,"modulate:a",1.0,G.anim_speed_fast).tween_finished
	return true
	
func reset_line():
	SimonTween.start_tween(self,"line_end_position",Vector2.ZERO,G.anim_speed_fast*2)
	
func adjust_ability_level(adj:int):
	_ability_level += adj
	_ability_level_handle.text = str(_ability_level)
	
func show_level():
	if is_on_wheel() or is_in_inventory():
		_ability_fade = true
	
func hide_level():
	_ability_fade = false

func show_green_highlight():
	green_highlight_fade = true
	
func hide_green_highlight():
	green_highlight_fade = false

func on_mouse_entered():
	if (_is_highlighted):
		G.cursor_active.emit()
	
	show_level()
	G.display_tooltip.emit(_ability_name+"\n"+_ability_description)
	#display_adjacency_radius()

func set_distance_to_hit(distance:float):
	bottle_distance = distance
	
func get_distance_to_hit() -> float: 
	return bottle_distance

func on_mouse_exited():
	if _is_highlighted:
		G.cursor_inactive.emit()
		
	hide_level()
	G.hide_tooltip.emit()
	#hide_adjacency_radius()

func on_ability_pressed():
	G.dragging_ability.emit(self)
	
func on_ability_released():
	G.stop_dragging_ability.emit(self)
