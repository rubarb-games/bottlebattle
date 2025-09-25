class_name PlayerManager extends Control

enum PlayerStatus { IDLE, DRAGGING, INACTIVE, OTHER }
var _player_status:PlayerStatus = PlayerStatus.IDLE

enum Op { PLUS, MINUS, SHIELD_PLUS, SHIELD_MINUS }

static var Main:PlayerManager

@export var _playerHandle:Control
@export var _playerMarker:Marker2D
@export var _enemyHandle:Control
@export var _enemyMarker:Marker2D

@export var _enemy_bottle_handle:Control
@export var _player_bottle_handle:Control

@export var _player_health_handle:ProgressBar
@export var _player_shield_handle:ProgressBar
@export var _playerHealth:int
@export var _playerShield:int
@export var _player_health_text:RichTextLabel
@export var _player_shield_text:RichTextLabel
@export var _enemy_health_handle:ProgressBar
@export var _enemy_shield_handle:ProgressBar
@export var _enemy_health_text:RichTextLabel
@export var _enemy_shield_text:RichTextLabel
@export var _enemyHealth:int
@export var _enemyShield:int

@export var _playerCash:int = 0

var anim_time = 0.4

@export var _ability_indicator_handle:Control
@export var _all_enemy_encounters:Array[EnemyData]
@export var _default_enemy_encounter:EnemyData

@export var _buff_area_handle:Control
@export var _all_buffs:Array[Buff]
@export var _buff_spacing:float = 40.0
@export var _buff_scene:PackedScene

@export var _shoot_curve:Curve
@export var _strike_curve:Curve
@export var _shake_curve:Curve

# Called when the node enters the scene tree for the first time.
func _ready():
	Main = self
	
	#Register class
	G.register_manager.emit(self)
	
	G.execute_ability.connect(on_execute_ability)
	G.adjust_cash.connect(on_adjust_cash)
	
	G.dragging_ability.connect(on_dragging)
	G.stop_dragging_ability.connect(on_stop_dragging)
	
	_enemyHandle.position.y += 25
	_enemyHandle.modulate.a = 0
	_ability_indicator_handle.modulate.a = 0

	G.buff_elapsed.connect(on_buff_elapsed)
	G.next_turn_started.connect(on_next_turn_started)

	G.adjust_cash.emit(0)
	initialize_player()
	
func initialize_player():
	_playerHealth = 100
	_playerShield = 0
	
func start_gameplay_round():
	start_new_encounter()
	
func end_gameplay_round():
	end_encounter()

func end_encounter():
	SimonTween.start_tween(_enemy_bottle_handle,"position:x",300.0,0.5).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"position:x",200,0.35).set_relative(true)

func start_new_encounter():
	var enc:EnemyData = GameManager.Main.get_encounter_manager().get_encounter_data()
	
	_enemyHealth = enc._health
	_enemyShield = enc._shield
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
	if (_playerHealth < 1):
		player_die()
		return false
		
	if (_enemyHealth < 1):
		enemy_die()
		return false
	
	_player_health_text.text = str(_playerHealth)
	_enemy_health_text.text = str(_enemyHealth)
	
	_player_shield_text.text = str(_playerShield)
	_enemy_shield_text.text = str(_enemyShield)
	
	
	_player_health_handle.value = _playerHealth
	_enemy_health_handle.value = _enemyHealth
	
	_player_shield_handle.value = _playerShield
	_enemy_shield_handle.value = _enemyShield
	
	return true

func adjust_player_health(damage:float, op:Op):
	match op:
		Op.PLUS:
			_playerHealth += damage
		Op.MINUS:
			_playerShield -= damage
			damage = _playerShield < 0 if abs(_playerShield) else 0
			_playerShield = clamp(_playerShield,0,50)
			_playerHealth -= damage
		Op.SHIELD_PLUS:
			_playerShield += damage

func adjust_enemy_health(damage:float, op:Op):
	match op:
		Op.PLUS:
			_enemyHealth += damage
		Op.MINUS:
			_enemyHealth -= damage
			damage = _enemyShield < 0 if abs(_enemyShield) else 0
			_enemyShield = clamp(_playerShield,0,50)
			_enemyHealth -= damage
		Op.SHIELD_PLUS:
			_enemyShield += damage

func execute_ability(ability:Ability,mag:int,isPlayerAbility:bool):
	var data = ability._data
	var damage = mag
	print("AYYYY!!! TIME FOR DATAAAA")
	if (isPlayerAbility):
		match data._ability_type:
			AbilityData.Type.DAMAGE:
				print("DMGGGO?")
				adjust_enemy_health(damage,Op.MINUS)
				await ability_to_enemy(ability)
				G.popup_text.emit(str(damage)+" Damage!", _enemyHandle.global_position)
			AbilityData.Type.HEAL:
				adjust_player_health(damage,Op.PLUS)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Healed!", _playerHandle.global_position)
			AbilityData.Type.BUFF:
				add_buff(ability._data._buff_data)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Buffed!", _playerHandle.global_position)
			AbilityData.Type.SHIELD:
				adjust_player_health(damage,Op.SHIELD_PLUS)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Healed!", _playerHandle.global_position)
				
	else:
		match data._ability_type:
			AbilityData.Type.DAMAGE:
				adjust_player_health(damage,Op.MINUS)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Damage!", _playerHandle.global_position)
			AbilityData.Type.HEAL:
				adjust_enemy_health(damage,Op.PLUS)
				await ability_to_enemy(ability)
				G.popup_text.emit(str(damage)+" Healed!", _playerHandle.global_position)
		
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

func initialize_buff_list():
	_all_buffs = []

func add_buff(b:BuffData):
	if (check_for_existing_buff(b)):
		return
	
	var instance = _buff_scene.instantiate() as Buff
	instance.initialize_data(b)
	_buff_area_handle.add_child(instance)
	_all_buffs.append(instance)
	
	instance.global_position = _buff_area_handle.global_position
	instance.global_position.x += (_all_buffs.size() * (instance.size.x + _buff_spacing))
	
func evaluate_all_buffs(mag:float, move:AbilityData):
	for b in _all_buffs:
		mag = await evaluate_buff(mag,b,move)
		
	return mag
	
func evaluate_buff(mag:float,b:Buff,move:AbilityData):
	var buff_affected:bool = false
	var bd = b._data
	
	match move._ability_type:
		AbilityData.Type.DAMAGE:
			match bd.type:
				BuffData.Type.DAMAGE_UP:
					if move._ability_target == AbilityData.Target.ENEMY:
						mag += bd.magnitude
						buff_affected = true
				BuffData.Type.DAMAGE_REDUCTION:
					if move._ability_target == AbilityData.Target.PLAYER:
						mag = clamp(mag - bd.magnitude, 0, 100)
						buff_affected = true
						
	
	if buff_affected:
		await b.shake()
	return mag
	
	
func remove_buff(b:Buff):
	b.destroy()
	_all_buffs.erase(b)
	
	update_buff_layout()

func check_for_existing_buff(b:BuffData):
	for d in _all_buffs:
		if (b.name == d._data.name):
			d.update_duration(-b.duration)
			d.shake()
			return true
			
	return false

func update_buff_layout():
	var b:Buff
	for i in range(_all_buffs.size()):
		b = _all_buffs[i]
		b.global_position = _buff_area_handle.global_position
		b.global_position.x += (i * (b.size.x + _buff_spacing))

func on_adjust_cash(adjustment:int):
	print("ADDING CASH!!! "+str(adjustment))
	_playerCash += adjustment

func on_execute_ability(ability:Ability, magnitude:int,player_ability:bool):
	execute_ability(ability,magnitude,player_ability)

func on_dragging(a:Ability):
	_player_status = PlayerStatus.DRAGGING
	
func on_stop_dragging(a:Ability):
	_player_status = PlayerStatus.IDLE

func on_buff_elapsed(b:Buff):
	remove_buff(b)

func on_next_turn_started():
	pass
	#_playerShield = 0
	#_enemyShield = 0
	#update_health_values()
