class_name PlayerManager extends Control

@export var _playerHandle:Control
@export var _playerMarker:Marker2D
@export var _enemyHandle:Control
@export var _enemyMarker:Marker2D

@export var _enemy_bottle_handle:Control
@export var _player_bottle_handle:Control

@export var _player_health_handle:ProgressBar
@export var _playerHealth:int
@export var _player_health_text:RichTextLabel
@export var _enemy_health_handle:ProgressBar
@export var _enemy_health_text:RichTextLabel
@export var _enemyHealth:int

@export var _playerCash:int = 0

@export var _ability_indicator_handle:Control
@export var _all_enemy_encounters:Array[EnemyData]
@export var _default_enemy_encounter:EnemyData

@export var _shoot_curve:Curve
@export var _strike_curve:Curve
@export var _shake_curve:Curve

# Called when the node enters the scene tree for the first time.
func _ready():
	G.execute_ability.connect(on_execute_ability)
	G.adjust_cash.connect(on_adjust_cash)
	
	_enemyHandle.position.y += 25
	_enemyHandle.modulate.a = 0
	_ability_indicator_handle.modulate.a = 0
	#_enemy_bottle_handle.position.x += 300
	#update_health_values()
	
func start_gameplay_round():
	start_new_encounter()
	
func end_gameplay_round():
	end_encounter()

func end_encounter():
	SimonTween.start_tween(_enemy_bottle_handle,"position:x",300.0,0.5).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"position:x",200,0.35).set_relative(true)

func start_new_encounter():
	var enc:EnemyData
	if (_all_enemy_encounters.size() < 1):
		print_rich("[color=RED]ALL ENEMY ENCOUNTERS EXHAUSTED!")
		enc = _default_enemy_encounter
	else:
		enc = _all_enemy_encounters.pop_back()
	
	_enemyHealth = enc._health
	_enemy_health_handle.max_value = enc._health
	update_health_values()
	enemy_spawn()
	
	SimonTween.start_tween(_enemyHandle,"position:x",-200,0.35).set_relative(true)
	await SimonTween.start_tween(_enemy_bottle_handle,"position:x",-300.0,0.5).set_relative(true).tween_finished
	
	G.start_encounter.emit(enc)

func is_player_alive():
	return true if _playerHealth > 0 else false
	
func is_enemy_alive():
	return true if _enemyHealth > 0 else false
	
func update_health_values():
	print("CHECKIN!!!")
	if (_playerHealth < 1):
		player_die()
		return false
		
	if (_enemyHealth < 1):
		enemy_die()
		return false
	
	_player_health_text.text = str(_playerHealth)
	_enemy_health_text.text = str(_enemyHealth)
	
	_player_health_handle.value = _playerHealth
	_enemy_health_handle.value = _enemyHealth
	return true

func execute_ability(ability:Ability,mag:int,isPlayerAbility:bool):
	var data = ability._data
	var damage = ability.get_magnitude()

	if (isPlayerAbility):
		_enemyHealth -= damage
		await ability_to_enemy(ability)
		G.popup_text.emit(str(damage)+" Damage!", _enemyHandle.global_position)
	else:
		_playerHealth -= damage
		await ability_to_player(ability)
		G.popup_text.emit(str(damage)+" Damage!", _playerHandle.global_position)
		
	return update_health_values()

func ability_to_enemy(a:Ability):
	_ability_indicator_handle.modulate.a = 1.0
	var initial_ability_position = a.global_position
	await SimonTween.start_tween(a,"global_position",_enemyMarker.global_position-a.global_position,0.35,_strike_curve).set_relative(true).tween_finished
	enemy_hit()
	SimonTween.start_tween(a,"global_position",initial_ability_position,0.75,_shoot_curve)
	return

func ability_to_player(a:Ability):
	_ability_indicator_handle.modulate.a = 1.0
	var initial_ability_position = a.global_position
	await SimonTween.start_tween(a,"global_position",_playerMarker.global_position-a.global_position,0.35,_strike_curve).set_relative(true).tween_finished
	enemy_hit()
	SimonTween.start_tween(a,"global_position",initial_ability_position,0.75,_shoot_curve)
	return

func ability_from_player_to_enemy():
	_ability_indicator_handle.global_position = _playerHandle.global_position
	#await SimonTween.start_tween(_ability_indicator_handle,"modulate:a",1.0,0.25).tween_finished
	_ability_indicator_handle.modulate.a = 1.0
	await SimonTween.start_tween(_ability_indicator_handle,"global_position",_enemyHandle.global_position,0.65,_shoot_curve).tween_finished
	enemy_hit()
	SimonTween.start_tween(_ability_indicator_handle,"modulate:a",0.0,0.25)
	return
	
func ability_from_enemy_to_player():
	pass
	
func ability_on_player():
	pass
	
func ability_on_enemy():
	pass
	
func ability_in_center():
	pass

func player_die():
	G.player_die.emit()
	
func enemy_die():
	SimonTween.start_tween(_enemyHandle,"position:y",25.0,0.5).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"modulate:a",0.0,0.65)
	G.enemy_die.emit()

func enemy_spawn():
	SimonTween.start_tween(_enemyHandle,"position:y",-25.0,0.5).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"modulate:a",1.0,0.65)
	pass

func enemy_hit():
	hit_character(_enemyHandle)
	
func player_hit():
	hit_character(_playerHandle)
	
func hit_character(char:Control):
	SimonTween.start_tween(char,"position:x",25.0,0.4,_shake_curve).set_relative(true)

func on_adjust_cash(adjustment:int):
	print("ADDING CASH!!! "+str(adjustment))
	_playerCash += adjustment

func on_execute_ability(ability:Ability, magnitude:int,player_ability:bool):
	execute_ability(ability,magnitude,player_ability)
