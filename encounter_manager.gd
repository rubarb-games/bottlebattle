class_name EncounterManager extends Control

@export var _encounter_list:Array[GameEncounters]
@export var _default_encounter:GameEncounters

@export var _all_enemy_encounters:Array[EnemyData]
@export var _default_enemy_encounter:EnemyData
var _current_encounter:GameEncounters

#Encounter stats
var round_number:int = 0

#Debug
@export var _win_encounter_button:Button

# Called when the node enters the scene tree for the first time.
func _ready():
	#Register class
	G.register_manager.emit(self)
	
	G.enemy_die.connect(on_enemy_die)
	G.loot_picked.connect(on_loot_picked)
	G.intro_loot_picked.connect(on_loot_picked)
	
	G.round_gameplay_start.connect(on_gameplay_start)
	G.round_gameplay_end.connect(on_gameplay_end)
	G.next_turn_started.connect(on_next_turn)
	
	_win_encounter_button.pressed.connect(on_enemy_die)

func get_next_encounter():
	
	_current_encounter = _encounter_list.pop_front()
	if (!_current_encounter):
		_current_encounter = _default_encounter
		
	match _current_encounter._type:
		GameEncounters.Type.ENCOUNTER:
			GameManager.Main.start_gameplay_round()
		GameEncounters.Type.LOOT:
			GameManager.Main.start_loot_round()
		GameEncounters.Type.SHOP:
			GameManager.Main.start_shop_round()
		GameEncounters.Type.INTRO:
			GameManager.Main.start_intro_round()
			
	G.start_encounter.emit()
	G.round_new_start.emit()
	
func get_encounter_data():
	return _current_encounter
	
	var enc:GameEncounters
	if (_all_enemy_encounters.size() < 1):
		print_rich("[color=RED]ALL ENEMY ENCOUNTERS EXHAUSTED!")
		enc = _default_encounter
	else:
		enc = _current_encounter
		
	return enc
	
func on_enemy_die():
	get_next_encounter()

func on_loot_picked():
	get_next_encounter()

func on_gameplay_start():
	round_number = 0
	
func on_gameplay_end():
	pass
	
func on_next_turn():
	round_number += 1
	G.popup_round_timer_text.emit("Round "+str(round_number))
