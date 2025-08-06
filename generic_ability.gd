class_name Ability extends Control

enum AbilityStatus { LOOT, ON_WHEEL, IDLE, ENEMY, OTHER }
var _status:AbilityStatus

var _dragging:bool = false
var _adjacency_radius:float = 250.0

var _size:float = 40.0

var _magnitude:int = 5
var _initial_magnitude:int = 0

var _initial_placement:float = -1

@export var _ability_name:String
@export var _ability_description:String

@export var _ability_button_handle:Button
@export var _bright_flash:ColorRect
@export var _bright_flash_curve:Curve
@export var _shake_curve:Curve
@export var _spawn_curve:Curve

@export var _adjacency_bonus_indicator:TextureRect

@export var _damage_numbers_handle:RichTextLabel
@export var _ability_sprite:Sprite2D

var _data:AbilityData

var _wheel_placement:float = -1

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
	_adjacency_bonus_indicator.size = Vector2(_adjacency_radius,_adjacency_radius)
	_adjacency_bonus_indicator.position -= Vector2(_adjacency_radius/2,_adjacency_radius/2)
	_adjacency_bonus_indicator.position += Vector2(20,20)
	_adjacency_bonus_indicator.modulate.a = 0
	_damage_numbers_handle.modulate.a = 0
	_initial_magnitude = _magnitude
	
	self.scale = Vector2.ZERO
	SimonTween.start_tween(self,"scale",Vector2(1,1),0.5+randf_range(0.0,0.4),_spawn_curve).set_relative(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func execute():
	pass

func destroy():
	await SimonTween.start_tween(self,"scale",Vector2(-1,-1),0.5+randf_range(0.0,0.4),_spawn_curve).set_relative(true).tween_finished
	self.queue_free()

func set_normal():
	_status = AbilityStatus.IDLE
	
func set_on_wheel():
	_status = AbilityStatus.ON_WHEEL

func set_loot():
	_status = AbilityStatus.LOOT

func set_enemy():
	_status = AbilityStatus.ENEMY

func is_loot():
	return true if _status == AbilityStatus.LOOT else false
	
func is_on_wheel():
	return true if _status == AbilityStatus.ON_WHEEL else false

func is_enemy():
	return true if _status == AbilityStatus.ENEMY else false

func bright_flash():
	SimonTween.start_tween(_bright_flash,"modulate:a",1.0,0.7,_bright_flash_curve).set_relative(true).set_start_snap(true)

func get_magnitude():
	return _magnitude

func adjust_magnitude(adj:int):
	_magnitude += adj

func set_magnitude(mag:int):
	_magnitude = mag
	
func reset_magnitude():
	_magnitude = _initial_magnitude

func damage_numbers_popup():
	_damage_numbers_handle.text = str(_magnitude)
	SimonTween.start_tween(_damage_numbers_handle,"modulate:a",1.0,0.25)
	await SimonTween.start_tween(_damage_numbers_handle,"position:y",-_size,0.4).tween_finished
	return
	
func damage_numbers_shake():
	await SimonTween.start_tween(_damage_numbers_handle,"scale",Vector2(0.5,0.5),0.25,_shake_curve).set_relative(true).tween_finished
	return
	
func damage_numbers_update(num:int):
	_damage_numbers_handle.text = str(num)
	await damage_numbers_shake()
	return
	
func damage_numbers_go_down():
	SimonTween.start_tween(_damage_numbers_handle,"modulate:a",0.0,0.25)
	await SimonTween.start_tween(_damage_numbers_handle,"position:y",_size,0.4).tween_finished
	return

func display_adjacency_radius():
	if (is_on_wheel()):
		SimonTween.start_tween(_adjacency_bonus_indicator,"modulate:a",1.0,0.75).set_relative(true)
	
func hide_adjacency_radius():
	if (is_on_wheel()):
		SimonTween.start_tween(_adjacency_bonus_indicator,"modulate:a",0.0,0.75)

func on_mouse_entered():
	G.display_tooltip.emit(_ability_name+"\n"+_ability_description)
	display_adjacency_radius()

func on_mouse_exited():
	G.hide_tooltip.emit()
	hide_adjacency_radius()

func on_ability_pressed():
	G.dragging_ability.emit(self)
	
func on_ability_released():
	G.stop_dragging_ability.emit(self)
