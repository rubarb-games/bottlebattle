class_name GameManager extends Control

enum PlayerStatus { IDLE, DRAGGING, INACTIVE }
var _player_status:PlayerStatus = PlayerStatus.IDLE


# Called when the node enters the scene tree for the first time.
func _ready():
	G.dragging_ability.connect(on_dragging)
	G.stop_dragging_ability.connect(on_stop_dragging)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_dragging(a:Ability):
	_player_status = PlayerStatus.DRAGGING
	
func on_stop_dragging(a:Ability):
	_player_status = PlayerStatus.IDLE
