class_name PlayerManager extends Control

@export var _playerHandle:Control
@export var _enemyHandle:Control

@export var _player_health_handle:ProgressBar
@export var _playerHealth:int
@export var _enemy_health_handle:ProgressBar
@export var _enemyHealth:int

@export var _ability_indicator_handle:Control

@export var _all_enemy_encounters:Array[EnemyData]

@export var _default_enemy_encounter:EnemyData


# Called when the node enters the scene tree for the first time.
func _ready():
	G.execute_ability.connect(on_execute_ability)
	
	_ability_indicator_handle.modulate.a = 0
	#update_health_values()
	
func start_gameplay_round():
	start_new_encounter()
	
func end_gameplay_round():
	pass

func start_new_encounter():
	var enc:EnemyData
	if (_all_enemy_encounters.size() < 1):
		print_rich("[color=RED]ALL ENEMY ENCOUNTERS EXHAUSTED!")
		enc = _default_enemy_encounter
	else:
		enc = _all_enemy_encounters.pop_back()
	
	_enemyHealth = enc._health
	update_health_values()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func update_health_values():
	if (_playerHealth < 1):
		player_die()
		return
		
	if (_enemyHealth < 1):
		enemy_die()
		return
	
	_player_health_handle.value = _playerHealth
	_enemy_health_handle.value = _enemyHealth

func ability_from_player_to_enemy():
	_ability_indicator_handle.global_position = _playerHandle.global_position
	await SimonTween.start_tween(_ability_indicator_handle,"modulate:a",1.0,0.25).tween_finished
	await SimonTween.start_tween(_ability_indicator_handle,"global_position",_enemyHandle.global_position,1).tween_finished
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
	G.enemy_die.emit()

func on_execute_ability(ability:AbilityData, combo:int):
	pass
	match ability._ability_name:
		"Strike":
			var damage = 5 * combo
			_enemyHealth -= damage
			await ability_from_player_to_enemy()
			G.popup_text.emit(str(damage)+" Damage!", _enemyHandle.global_position)
			update_health_values()
		"Heavy blow":
			var damage = 20 * combo
			_enemyHealth -= damage
			await ability_from_player_to_enemy()
			G.popup_text.emit(str(damage)+" Damage!", _enemyHandle.global_position)
			update_health_values()
