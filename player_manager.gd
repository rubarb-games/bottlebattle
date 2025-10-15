class_name PlayerManager extends Control

enum PlayerStatus { IDLE, DRAGGING, INACTIVE, OTHER }
var _player_status:PlayerStatus = PlayerStatus.IDLE

enum Op { PLUS, MINUS, SHIELD_PLUS, SHIELD_MINUS }

static var Main:PlayerManager

@export var _playerHandle:Control
@export var _playerMarker:Marker2D
@export var _enemyHandle:Control
@export var _enemyMarker:Marker2D

@export var buff_line:Line2D
var buff_line_end_point:Vector2 = Vector2.ZERO

@export var _enemy_bottle_handle:Control
@export var _player_bottle_handle:Control

@export var _player_sprite:Sprite2D
@export var _enemy_sprite:Sprite2D
@export var _player_name_handle:Label
@export var _enemy_name_handle:Label

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
@export var _enemy_buff_area_handle:Control
@export var _all_buffs:Array[Buff]
@export var _all_enemy_buffs:Array[Buff]
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
	_playerHealth = 20
	_playerShield = 0
	
	buff_line.modulate.a = 0.0
	
	#Handles manually
	#_player_sprite = X
	
func _process(delta: float) -> void:
	buff_line.points[1] = buff_line_end_point
	
func start_gameplay_round():
	start_new_encounter()
	
func end_gameplay_round():
	end_encounter()

func end_encounter():
	SimonTween.start_tween(_enemy_bottle_handle,"position:x",300.0,G.anim_speed_medium).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"position:x",200,G.anim_speed_fast).set_relative(true)

func start_new_encounter():
	var enc:EnemyData = GameManager.Main.get_encounter_manager().get_encounter_data()._enemy
	
	_enemyHealth = enc._health
	_enemyShield = enc._shield
	_enemy_health_handle.max_value = enc._health
	
	remove_all_enemy_buffs()
	
	_enemy_sprite.texture = enc._portrait
	_enemy_name_handle.text = enc._name
	
	update_health_values()
	enemy_spawn()
	
	SimonTween.start_tween(_enemyHandle,"position:x",-200,G.anim_speed_fast).set_relative(true)
	await SimonTween.start_tween(_enemy_bottle_handle,"position:x",-300.0,G.anim_speed_medium).set_relative(true).tween_finished
	
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
			damage = abs(_playerShield) if _playerShield < 0 else 0
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
			damage = abs(_enemyShield) if _enemyShield < 0 else 0
			_enemyShield = clamp(_enemyShield,0,50)
			_enemyHealth -= damage
		Op.SHIELD_PLUS:
			_enemyShield += damage

func execute_ability(ability:Ability,mag:int,isPlayerAbility:bool):
	var data = ability._data
	var damage = mag
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
			AbilityData.Type.DEBUFF:
				add_buff(ability._data._buff_data,false)
				await ability_to_enemy(ability)
				G.popup_text.emit(str(damage)+" Debuffed!", _enemyHandle.global_position)
			AbilityData.Type.SHIELD:
				adjust_player_health(damage,Op.SHIELD_PLUS)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" SHIELD!", _playerHandle.global_position)
				
	else:
		match data._ability_type:
			AbilityData.Type.DAMAGE:
				adjust_player_health(damage,Op.MINUS)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Damage!", _playerHandle.global_position)
			AbilityData.Type.HEAL:
				adjust_enemy_health(damage,Op.PLUS)
				await ability_to_enemy(ability)
				G.popup_text.emit(str(damage)+" Healed!", _enemyHandle.global_position)
			AbilityData.Type.BUFF:
				add_buff(ability._data._buff_data,false)
				await ability_to_enemy(ability)
				G.popup_text.emit("Buffed!", _enemyHandle.global_position)
			AbilityData.Type.DEBUFF:
				add_buff(ability._data._buff_data,true)
				await ability_to_player(ability)
				G.popup_text.emit(str(damage)+" Debuffed!", _playerHandle.global_position)
			AbilityData.Type.SHIELD:
				adjust_enemy_health(damage,Op.SHIELD_PLUS)
				await ability_to_enemy(ability)
				G.popup_text.emit(str(damage)+" SHIELD!", _enemyHandle.global_position)
		
	return update_health_values()

func ability_to_enemy(a:Ability):
	_ability_indicator_handle.modulate.a = 1.0
	var initial_ability_position = a.global_position
	await SimonTween.start_tween(a,"global_position",_enemyMarker.global_position-a.global_position,G.anim_speed_fast,_strike_curve).set_relative(true).tween_finished
	enemy_hit()
	SimonTween.start_tween(a,"global_position",initial_ability_position,G.anim_speed_medium,_shoot_curve)
	return

func ability_to_player(a:Ability):
	_ability_indicator_handle.modulate.a = 1.0
	var initial_ability_position = a.global_position
	await SimonTween.start_tween(a,"global_position",_playerMarker.global_position-a.global_position,G.anim_speed_fast,_strike_curve).set_relative(true).tween_finished
	enemy_hit()
	SimonTween.start_tween(a,"global_position",initial_ability_position,G.anim_speed_medium,_shoot_curve)
	return

func ability_from_player_to_enemy():
	_ability_indicator_handle.global_position = _playerHandle.global_position
	#await SimonTween.start_tween(_ability_indicator_handle,"modulate:a",1.0,0.25).tween_finished
	_ability_indicator_handle.modulate.a = 1.0
	await SimonTween.start_tween(_ability_indicator_handle,"global_position",_enemyHandle.global_position,G.anim_speed_medium,_shoot_curve).tween_finished
	enemy_hit()
	SimonTween.start_tween(_ability_indicator_handle,"modulate:a",0.0,G.anim_speed_fast)
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
	SimonTween.start_tween(_enemyHandle,"position:y",25.0,G.anim_speed_medium).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"modulate:a",0.0,G.anim_speed_medium)
	G.enemy_die.emit()

func enemy_spawn():
	SimonTween.start_tween(_enemyHandle,"position:y",-25.0,G.anim_speed_medium).set_relative(true)
	SimonTween.start_tween(_enemyHandle,"modulate:a",1.0,G.anim_speed_medium)
	pass

func enemy_hit():
	hit_character(_enemyHandle)
	
func player_hit():
	hit_character(_playerHandle)
	
func hit_character(char:Control):
	SimonTween.start_tween(char,"position:x",25.0,G.anim_speed_fast,_shake_curve).set_relative(true)

func initialize_buff_list():
	_all_buffs = []

func add_buff(b:BuffData, is_player:bool = true):
	if (check_for_existing_buff(b,is_player)):
		return
	
	var instance = _buff_scene.instantiate() as Buff
	instance.initialize_data(b)
	if (is_player):
		_buff_area_handle.add_child(instance)
		_all_buffs.append(instance)
		instance.global_position = _buff_area_handle.global_position
		instance.global_position.x += (_all_buffs.size() * (instance.size.x + _buff_spacing))
	else:
		_enemy_buff_area_handle.add_child(instance)
		_all_enemy_buffs.append(instance)
		instance.global_position = _enemy_buff_area_handle.global_position
		instance.global_position.x -= (_all_enemy_buffs.size() * (instance.size.x - _buff_spacing))
	
func evaluate_all_buffs(mag:float, move:Ability,is_player:bool = true):
	var mag_adj = 0
	var current_mag_adj = 0
	if (is_player):
		for b in _all_buffs:
			current_mag_adj  = await evaluate_buff(mag,b,move)
			mag_adj += current_mag_adj
	else:
		for b in _all_enemy_buffs:
			current_mag_adj  = await evaluate_buff(mag,b,move)
			mag_adj += current_mag_adj

	return mag_adj
	
func evaluate_buff(mag:float,b:Buff,move:Ability):
	var buff_affected:bool = false
	var bd = b._data
	var mag_adj = 0.0
	
	match move._data._ability_type:
		AbilityData.Type.DAMAGE:
			match bd.type:
				BuffData.Type.DAMAGE_UP:
					if move._data._ability_target == AbilityData.Target.ENEMY:
						mag_adj = bd.magnitude
						buff_affected = true
						await line_to_location(b.global_position+(b.size/2),move.global_position)
						move.damage_numbers_update(mag_adj,"BLUE")
						await move.bright_flash()
						await reset_line()
				BuffData.Type.DAMAGE_REDUCTION:
					if move._data._ability_target == AbilityData.Target.PLAYER:
						mag_adj = mag - bd.magnitude if mag > bd.magnitude else 0
						await line_to_location(b.global_position+(b.size/2),move.global_position)
						move.damage_numbers_update(mag_adj,"BLUE")
						await move.bright_flash()
						await reset_line()
						buff_affected = true
						
	
	if buff_affected:
		await b.shake()
	return mag_adj
	
	
func remove_all_enemy_buffs():
	for b in _all_enemy_buffs:
		remove_buff(b)
	
func remove_buff(b:Buff):
	_all_buffs.erase(b)
	_all_enemy_buffs.erase(b)
	b.destroy()
	
	update_buff_layout()

func check_for_existing_buff(b:BuffData, is_player:bool = true):
	if (is_player):
		for d in _all_buffs:
			if (b.name == d._data.name):
				d.update_duration(-b.duration)
				d.shake()
				return true
	else:
		for d in _all_enemy_buffs:
			if (b.name == d._data.name):
				d.update_duration(-b.duration)
				d.shake()
				return true
			
	return false

func update_buff_layout():
	var b:Buff
	if _all_buffs.size() > 0:
		for i in range(_all_buffs.size()):
			b = _all_buffs[i]
			b.global_position = _buff_area_handle.global_position
			b.global_position.x += (i * (b.size.x + _buff_spacing))
		
	if _all_enemy_buffs.size() > 0:
		for l in range(_all_enemy_buffs.size()):
			b = _all_enemy_buffs[l]
			b.global_position = _enemy_buff_area_handle.global_position
			b.global_position.x -= (l * (b.size.x - _buff_spacing))

func line_to_location(start_pos:Vector2,pos:Vector2):
	buff_line.global_position = start_pos
	buff_line.modulate.a = 0.0
	buff_line_end_point = Vector2.ZERO
	SimonTween.start_tween(self,"buff_line_end_point",pos - buff_line.global_position,G.anim_speed_fast).set_relative(true)
	await SimonTween.start_tween(buff_line,"modulate:a",1.0,G.anim_speed_fast).tween_finished
	return true
	
func reset_line():
	SimonTween.start_tween(self,"buff_line_end_point",Vector2.ZERO,G.anim_speed_fast*2)

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
