class_name Buff extends ColorRect

@export var _data:BuffData
@export var _shake_curve:Curve
@export var _visual_handle:Control
@export var _duration_label:RichTextLabel
var _elapsed_duration:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.next_turn_started.connect(on_next_turn)
	
	_visual_handle.mouse_entered.connect(on_mouse_entered)
	_visual_handle.mouse_exited.connect(on_mouse_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func initialize_data(b):
	_data = b
	_elapsed_duration = 0
	_duration_label.text = str(_data.duration)

func update_duration(new_dur:int):
	_elapsed_duration += new_dur
	_duration_label.text = str(_data.duration - _elapsed_duration)

func shake():
	await SimonTween.start_tween(self,"scale",Vector2(-0.5,-0.5),0.4,_shake_curve).set_relative(true).tween_finished
	return true

func destroy():
	self.queue_free()

func on_next_turn():
	_elapsed_duration += 1
	_duration_label.text = str(_data.duration - _elapsed_duration)
	
	if (_elapsed_duration > _data.duration):
		G.buff_elapsed.emit(self)

func on_mouse_entered():
	G.display_tooltip.emit(_data.name+"\n"+_data.description)
	
func on_mouse_exited():
	G.hide_tooltip.emit()
