class_name EncounterManager extends Control

@export var _encounter_list:Array[GameEncounters]
@export var _default_encounter:GameEncounters

@export var _all_enemy_encounters:Array[EnemyData]
@export var _default_enemy_encounter:EnemyData

#Debug
@export var _win_encounter_button:Button

# Called when the node enters the scene tree for the first time.
func _ready():
	#Register class
	G.register_manager.emit(self)
	
	G.enemy_die.connect(on_enemy_die)
	G.loot_picked.connect(on_loot_picked)
	
	_win_encounter_button.pressed.connect(on_enemy_die)

func get_next_encounter():
	var enc:GameEncounters = _encounter_list.pop_back()
	if (!enc):
		enc = _default_encounter
		
	match enc._type:
		GameEncounters.Type.ENCOUNTER:
			GameManager.Main.start_gameplay_round()
		GameEncounters.Type.LOOT:
			GameManager.Main.start_loot_round()
		GameEncounters.Type.SHOP:
			GameManager.Main.start_shop_round()
	
func get_encounter_data():
	var enc:EnemyData
	if (_all_enemy_encounters.size() < 1):
		print_rich("[color=RED]ALL ENEMY ENCOUNTERS EXHAUSTED!")
		enc = _default_enemy_encounter
	else:
		enc = _all_enemy_encounters.pop_back()
		
	return enc
	
func on_enemy_die():
	get_next_encounter()

func on_loot_picked():
	get_next_encounter()
