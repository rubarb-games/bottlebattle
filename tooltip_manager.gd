class_name TooltipManager extends Control

@export var _tootlip_handle:Control
@export var _tooltip_text:RichTextLabel

@export var _text_popup_handle:Control
@export var _text_popup_text_handle:RichTextLabel
@export var _cash_label:Label

@export var _status_text_label:Label

@export var _text_popup_curve:Curve

@export var _round_timer_handle:Label
var _round_timer_initial_position:Vector2

var text_popup_timer:float = 0.0
var text_popup_timer_max:float = 0.2
var is_text_popup:bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	#Register class
	G.register_manager.emit(self)
	
	G.display_tooltip.connect(on_display_tooltip)
	G.hide_tooltip.connect(on_hide_tooltip)
	
	G.display_status_text.connect(on_display_status_text)
	
	G.adjust_cash.connect(money_adjusted)
	G.popup_text.connect(on_popup_text)
	_text_popup_handle.modulate.a = 0
	
	G.popup_round_timer_text.connect(on_popup_round_timer)
	_round_timer_initial_position = _round_timer_handle.global_position
	_round_timer_handle.text = ""
	
	on_hide_tooltip()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_tootlip_handle.position = get_global_mouse_position()
	_tootlip_handle.position.x -= (_tootlip_handle.size.x / 2)
	
	if is_text_popup and text_popup_timer < text_popup_timer_max:
		text_popup_timer += delta
		_text_popup_handle.modulate.a = (text_popup_timer/text_popup_timer_max)
	elif !is_text_popup and text_popup_timer > 0.0:
		text_popup_timer -= delta
		_text_popup_handle.modulate.a = (text_popup_timer/text_popup_timer_max)
		

func on_display_tooltip(text:String):
	_tooltip_text.text = text
	await SimonTween.start_tween(_tootlip_handle,"modulate:a",1.0,0.4).set_end_snap(true).tween_finished
	_tooltip_text.modulate.a = 1

func on_hide_tooltip():
	SimonTween.start_tween(_tootlip_handle,"modulate:a",0.0,0.4).set_end_snap(true)

func on_popup_text(text:String, pos:Vector2):
	_text_popup_handle.position = pos
	_text_popup_handle.position.x -= _text_popup_handle.size.x / 2
	_text_popup_text_handle.text = text
	#SimonTween.start_tween(_text_popup_handle,"modulate:a",1.0,1.25,_text_popup_curve).set_relative(true)
	#SimonTween.start_tween(_text_popup_handle,"position:y",-50.0,0.2).set_relative(true)
	is_text_popup = true
	await get_tree().create_timer(1.0).timeout
	is_text_popup = false
	#SimonTween.start_tween(_text_popup_handle,"modulate:a",-1.0,1.25,_text_popup_curve).set_relative(true)
	#SimonTween.start_tween(_text_popup_handle,"position:y",50.0,0.2).set_relative(true)

func on_display_status_text(text:String):
	_status_text_label.text = text
	
func on_hide_status_text():
	pass

func on_popup_round_timer(text:String):
	var slide_distance = 80
	
	_round_timer_handle.modulate.a = 0.0
	_round_timer_handle.global_position = _round_timer_initial_position
	_round_timer_handle.global_position.x += slide_distance
	_round_timer_handle.text = text
	
	SimonTween.start_tween(_round_timer_handle,"modulate:a",1.0,G.anim_speed_fast,null).set_relative(true)
	await SimonTween.start_tween(_round_timer_handle,"global_position:x",-slide_distance,G.anim_speed_fast,null).set_relative(true).tween_finished
	#is_text_popup = true
	await get_tree().create_timer(G.anim_speed_slow).timeout
	#is_text_popup = false
	SimonTween.start_tween(_round_timer_handle,"modulate:a",-1.0,G.anim_speed_fast,null).set_relative(true)
	await SimonTween.start_tween(_round_timer_handle,"global_position:x",-slide_distance,G.anim_speed_fast,null).set_relative(true).tween_finished
	

func money_adjusted(adjustment:int):
	await get_tree().process_frame
	_cash_label.text = "Coins: "+str(GameManager.Main._player_manager_handle._playerCash)+"c"
