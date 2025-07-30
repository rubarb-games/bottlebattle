class_name Ability extends Control

enum AbilityStatus { LOOT, ON_WHEEL, IDLE, OTHER }
var _status:AbilityStatus

var _dragging:bool = false

@export var _ability_name:String
@export var _ability_description:String

@export var _ability_button_handle:Button

@export var _ability_sprite:Sprite2D

var _data:AbilityData

var _wheel_placement:float = 0.0

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func execute():
	pass

func on_mouse_entered():
	G.display_tooltip.emit(_ability_name+"\n"+_ability_description)

func on_mouse_exited():
	G.hide_tooltip.emit()

func on_ability_pressed():
	G.dragging_ability.emit(self)
	
func on_ability_released():
	G.stop_dragging_ability.emit(self)
