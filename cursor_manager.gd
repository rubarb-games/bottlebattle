extends Control

@export var _cursor_handle:Control
@export var _cursor_visuals:Sprite2D

@export var _cursor_active_sprite:Texture
@export var _cursor_idle_sprite:Texture
@export var _cursor_holding_sprite:Texture

@export var _cursor_normal_color:Color
@export var _cursor_action_available_color:Color
@export var _cursor_action_unavailable_color:Color

@export var _cursor_illegal_action_curve:Curve
@export var _cursor_bounce:Curve

@export var _is_override_position:float = 0.0
@export var _override_position:Vector2 = Vector2(0.0,0.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.cursor_active_sprite.connect(set_cursor_active)
	G.cursor_grab_sprite.connect(set_cursor_holding)
	G.cursor_idle_sprite.connect(set_cursor_idle)
	
	G.cursor_active.connect(set_cursor_active_color)
	G.cursor_set_white.connect(set_cursor_normal_color)
	G.cursor_inactive.connect(set_cursor_inactive_color)
	
	G.cursor_set_green.connect(set_cursor_available_color)
	G.cursor_set_red.connect(set_cursor_unavailable_color)
	
	G.cursor_override_position.connect(on_override_position)
	G.cursor_resume_position.connect(on_resume_position)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	set_cursor_inactive_color()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_sprite_position(delta)

func update_sprite_position(delta:float):
		_cursor_handle.global_position = lerp(get_global_mouse_position(),_override_position,(_is_override_position*0.6))

func set_cursor_idle():
	_cursor_visuals.texture = _cursor_idle_sprite
	
func set_cursor_active():
	_cursor_visuals.texture = _cursor_active_sprite

func set_cursor_holding():
	_cursor_visuals.texture = _cursor_holding_sprite
	
func set_cursor_normal_color():
	_cursor_visuals.modulate = _cursor_normal_color
	
func set_cursor_available_color():
	set_cursor_bounce()
	_cursor_visuals.modulate = _cursor_action_available_color
	
func set_cursor_unavailable_color():
	_cursor_visuals.modulate = _cursor_action_unavailable_color
	
func set_cursor_active_color():
		_cursor_visuals.modulate.a = 1.0
	
func set_cursor_inactive_color():
	_cursor_visuals.modulate.a = 0.3
	
func set_cursor_bounce():
	SimonTween.start_tween(_cursor_handle,"scale",Vector2(2.0,2.0),G.anim_speed_slow,_cursor_illegal_action_curve).set_relative(true)
	
func set_cursor_error():
	SimonTween.start_tween(_cursor_handle,"position:x",10.0,G.anim_speed_fast,_cursor_illegal_action_curve).set_end_snap(true)

func on_resume_position():
	SimonTween.start_tween(self,"_is_override_position",0.0,G.anim_speed_slow,null)

func on_override_position(pos:Vector2):
	SimonTween.start_tween(self,"_is_override_position",1.0,G.anim_speed_slow,null)
	_override_position = pos
