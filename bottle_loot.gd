class_name BottleLoot extends Node

enum AbilityStatus { LOOT, OTHER }
var _status:AbilityStatus

@export var _bottle_data:Bottle

var _dragging:bool = false
var _adjacency_radius:float = 250.0

var _size:float = 40.0

var _initial_placement:float = -1

var bottle_distance:float = 0.0

@export var _bottle_name:String
@export var _bottle_description:String

@export var _bottle_button_handle:Button
@export var _bright_flash:ColorRect
@export var _green_flash:ColorRect
@export var _bright_flash_curve:Curve
@export var _green_flash_curve:Curve
@export var _shake_curve:Curve
@export var _spawn_curve:Curve

@export var _adjacency_bonus_indicator:TextureRect

@export var _bottle_sprite:TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	_bottle_button_handle.mouse_entered.connect(on_mouse_entered)
	_bottle_button_handle.mouse_exited.connect(on_mouse_exited)
	_bottle_button_handle.button_down.connect(on_ability_pressed)
	_bottle_button_handle.button_up.connect(on_ability_released)
	
	initialize()

func initialize():
	_adjacency_bonus_indicator.size = Vector2(_adjacency_radius,_adjacency_radius)
	_adjacency_bonus_indicator.position -= Vector2(_adjacency_radius/2,_adjacency_radius/2)
	_adjacency_bonus_indicator.position += Vector2(20,20)
	_adjacency_bonus_indicator.modulate.a = 0
	
	self.scale = Vector2.ZERO
	SimonTween.start_tween(self,"scale",Vector2(1,1),0.5+randf_range(0.0,0.4),_spawn_curve).set_relative(true)

func setup_bottle(b:Bottle):
	_bottle_data = b
	_bottle_name = _bottle_data.name
	_bottle_description = _bottle_data.description
	_bottle_sprite.texture = _bottle_data.bottle_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func execute():
	pass

func destroy():
	await SimonTween.start_tween(self,"scale",Vector2(-1,-1),0.5+randf_range(0.0,0.4),_spawn_curve).set_relative(true).tween_finished
	self.queue_free()

func set_dehighlight():
	SimonTween.start_tween(_bottle_sprite,"modulate",Color(0.,0.2,0.2,1),0.2,null).set_end_snap(true)

func set_highlight():
	SimonTween.start_tween(_bottle_sprite,"modulate",Color(1.0,1.0,1.0,1),0.2,null).set_end_snap(true)

func is_loot():
	return true if _status == AbilityStatus.LOOT else false

func bright_flash():
	SimonTween.start_tween(_bright_flash,"modulate:a",1.0,0.7,_bright_flash_curve).set_relative(true).set_start_snap(true)

func green_flash():
	_green_flash.scale = Vector2(0.5,0.5)
	SimonTween.start_tween(_green_flash,"modulate:a",1.0,1.0,_green_flash_curve).set_relative(true).set_start_snap(true)
	await SimonTween.start_tween(_green_flash,"scale",Vector2(1.0,1.0),1.0,_green_flash_curve).set_relative(true).set_end_snap(true).tween_finished
	_green_flash.scale = Vector2(1.0,1.0)

func on_mouse_entered():
	G.display_tooltip.emit(_bottle_name+"\n"+_bottle_description)

func set_distance_to_hit(distance:float):
	bottle_distance = distance
	
func get_distance_to_hit() -> float: 
	return bottle_distance

func on_mouse_exited():
	G.hide_tooltip.emit()

func on_ability_pressed():
	G.dragging_bottle.emit(self)
	
func on_ability_released():
	G.stop_dragging_bottle.emit(self)
