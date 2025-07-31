class_name GameManager extends Control

enum PlayerStatus { IDLE, DRAGGING, INACTIVE, OTHER }
var _player_status:PlayerStatus = PlayerStatus.IDLE

@export var _status_label:Label

enum RoundStatus { GAMEPLAY, IN_PROGRESS, LOOT, OTHER, GAMEOVER }
var _round_status:RoundStatus = RoundStatus.GAMEPLAY

@export var _bottle_manager_handle:BottleManager
@export var _player_manager_handle:PlayerManager
@export var _tooltip_manager_handle:TooltipManager
@export var _ability_wheel_manager_handle:AbilityWheelManager
@export var _loot_manager_handle:LootManager


# Called when the node enters the scene tree for the first time.
func _ready():
	G.dragging_ability.connect(on_dragging)
	G.stop_dragging_ability.connect(on_stop_dragging)
	
	G.round_gameplay_start.connect(on_round_gameplay_start)
	G.round_gameplay_end.connect(on_round_gameplay_end)
	
	G.round_loot_start.connect(on_round_loot_start)
	G.round_loot_end.connect(on_round_loot_end)
	
	G.round_other_start.connect(on_round_other_start)
	G.round_other_end.connect(on_round_other_end)
	
	G.round_gameover_start.connect(on_round_gameover_start)
	G.round_gameover_end.connect(on_round_gameover_end)
	
	G.player_die.connect(on_player_die)
	G.enemy_die.connect(on_enemy_die)
	
	initialize()
	
func initialize():
	G.round_gameplay_start.emit()



func change_round_status(rs:RoundStatus):
	#Exiting previous state
	match _round_status:
		RoundStatus.GAMEPLAY:
			G.round_gameover_end.emit()
		RoundStatus.LOOT:
			G.round_loot_end.emit()
		RoundStatus.IN_PROGRESS:
			pass
		RoundStatus.OTHER:
			G.round_other_end.emit()
		RoundStatus.GAMEOVER:
			G.round_gameover_end.emit()
	
	#Entering new state
	match rs:
		RoundStatus.GAMEPLAY:
			_round_status = rs
		RoundStatus.LOOT:
			_round_status = rs
		RoundStatus.IN_PROGRESS:
			_round_status = rs
		RoundStatus.OTHER:
			_round_status = rs
		RoundStatus.GAMEOVER:
			_round_status = rs

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_loot_phase():
	return true if _round_status == RoundStatus.LOOT else false
	
func is_gameplay_phase():
	return true if _round_status == RoundStatus.GAMEPLAY else false

func get_bottle():
	return _bottle_manager_handle

func get_wheel():
	return _ability_wheel_manager_handle
	
func get_player():
	return _player_manager_handle
	
func get_loot():
	return _loot_manager_handle

func on_dragging(a:Ability):
	_player_status = PlayerStatus.DRAGGING
	
func on_stop_dragging(a:Ability):
	_player_status = PlayerStatus.IDLE

func on_round_gameplay_start():
	change_round_status(RoundStatus.GAMEPLAY)
	
	_bottle_manager_handle.start_gameplay_round()
	_ability_wheel_manager_handle.start_gameplay_round()
	_player_manager_handle.start_gameplay_round()
	
func on_round_gameplay_end():
	pass
	
func on_round_loot_start():
	change_round_status(RoundStatus.LOOT)
	
	_status_label.text = "LOOT PHASE!"
	
func on_round_loot_end():
	pass
	
func on_round_other_start():
	pass
	
func on_round_other_end():
	pass

func on_round_gameover_start():
	change_round_status(RoundStatus.GAMEOVER)
	
	_status_label.text = "GAME OVER!"
	
func on_round_gameover_end():
	pass

func on_player_die():
	G.round_gameplay_end.emit()
	G.round_gameover_start.emit()
	
func on_enemy_die():
	G.round_gameplay_end.emit()
	G.round_loot_start.emit()
