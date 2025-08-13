class_name GameManager extends Control

#Singleton handle
static var Main:GameManager
static var Player:PlayerManager
static var Bottle:BottleManager
static var Loot:LootManager
static var AbilityWheel:AbilityWheelManager

var _state_delay:float = 1.0

enum RoundStatus { GAMEPLAY, IN_PROGRESS, LOOT, OTHER, GAMEOVER, SHOP }
var _round_status:RoundStatus = RoundStatus.GAMEPLAY

@export var _bottle_manager_handle:BottleManager
@export var _player_manager_handle:PlayerManager
@export var _tooltip_manager_handle:TooltipManager
@export var _ability_wheel_manager_handle:AbilityWheelManager
@export var _loot_manager_handle:LootManager
@export var _encounter_manager_handle:EncounterManager

# Called when the node enters the scene tree for the first time.
func _ready():
	Main = self
	
	G.round_gameplay_start.connect(on_round_gameplay_start)
	G.round_gameplay_end.connect(on_round_gameplay_end)
	
	G.round_loot_start.connect(on_round_loot_start)
	G.round_loot_end.connect(on_round_loot_end)
	
	G.round_other_start.connect(on_round_other_start)
	G.round_other_end.connect(on_round_other_end)
	
	G.round_gameover_start.connect(on_round_gameover_start)
	G.round_gameover_end.connect(on_round_gameover_end)
	
	G.register_manager.connect(on_register_manager)
	
	initialize()
	
func initialize():
	change_round_status(RoundStatus.GAMEPLAY)

func start_gameplay_round():
	change_round_status(RoundStatus.GAMEPLAY)
	
func start_loot_round():
	change_round_status(RoundStatus.LOOT)

func start_shop_round():
	change_round_status(RoundStatus.SHOP)

func change_round_status(rs:RoundStatus):
	#Exiting previous state
	match _round_status:
		RoundStatus.GAMEPLAY:
			G.round_gameplay_end.emit()
		RoundStatus.LOOT:
			G.round_loot_end.emit()
		RoundStatus.IN_PROGRESS:
			pass
		RoundStatus.OTHER:
			G.round_other_end.emit()
		RoundStatus.GAMEOVER:
			G.round_gameover_end.emit()
	
	await get_tree().create_timer(_state_delay).timeout
	
	#Entering new state
	match rs:
		RoundStatus.GAMEPLAY:
			_round_status = rs
			G.round_gameplay_start.emit()
		RoundStatus.LOOT:
			_round_status = rs
			G.round_loot_start.emit()
		RoundStatus.IN_PROGRESS:
			_round_status = rs
		RoundStatus.OTHER:
			_round_status = rs
			G.round_other_start.emit()
		RoundStatus.GAMEOVER:
			_round_status = rs
			G.round_gameover_start.emit()

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

func get_encounter_manager():
	return _encounter_manager_handle

func on_round_gameplay_start():
	await get_tree().process_frame
	
	_bottle_manager_handle.start_gameplay_round()
	_ability_wheel_manager_handle.start_gameplay_round()
	_player_manager_handle.start_gameplay_round()
	
func on_round_gameplay_end():
	_bottle_manager_handle.end_gameplay_round()
	_player_manager_handle.end_gameplay_round()
	_ability_wheel_manager_handle.end_gameplay_round()
	
func on_round_loot_start():
	G.display_status_text.emit("Loot phase!")
	
func on_round_loot_end():
	pass
	
func on_round_other_start():
	pass
	
func on_round_other_end():
	pass

func on_round_gameover_start():
	change_round_status(RoundStatus.GAMEOVER)
	
	G.display_status_text.emit("Game over!")
	
func on_round_gameover_end():
	pass

func on_player_die():
	change_round_status(RoundStatus.GAMEOVER)
	
func on_enemy_die():
	pass

func on_loot_picked():
	pass

func on_register_manager(obj:Object):
	if obj is PlayerManager:
		Player = obj
	if obj is BottleManager:
		Bottle = obj
	if obj is LootManager:
		Loot = obj
	if obj is AbilityWheelManager:
		AbilityWheel = obj
