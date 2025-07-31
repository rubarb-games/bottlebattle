class_name TooltipManager extends Control

@export var _tootlip_handle:Control
@export var _tooltip_text:RichTextLabel

@export var _text_popup_handle:Control
@export var _text_popup_text_handle:RichTextLabel

@export var _text_popup_curve:Curve

# Called when the node enters the scene tree for the first time.
func _ready():
	G.display_tooltip.connect(on_display_tooltip)
	G.hide_tooltip.connect(on_hide_tooltip)
	
	G.popup_text.connect(on_popup_text)
	_text_popup_handle.modulate.a = 0
	on_hide_tooltip()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_tootlip_handle.position = get_global_mouse_position()
	_tootlip_handle.position.x -= (_tootlip_handle.size.x / 2)

func on_display_tooltip(text:String):
	_tooltip_text.text = text
	await SimonTween.start_tween(_tootlip_handle,"modulate:a",1.0,0.4).set_end_snap(true).tween_finished
	_tooltip_text.modulate.a = 1

func on_hide_tooltip():
	SimonTween.start_tween(_tootlip_handle,"modulate:a",0.0,0.4).set_end_snap(true)

func on_popup_text(text:String, pos:Vector2):
	_text_popup_handle.position = pos
	_text_popup_handle.position.x += _text_popup_handle.size.x / 2
	_text_popup_text_handle.text = text
	SimonTween.start_tween(_text_popup_handle,"modulate:a",1.0,1.25,_text_popup_curve).set_relative(true)
	SimonTween.start_tween(_text_popup_handle,"position:y",-50.0,0.2).set_relative(true)
