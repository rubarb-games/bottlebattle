class_name EncounterMapManager extends Control

@export var _map_labels:Array[Label]
@export var _map_position:Marker2D
var _map_spacing:float = 180.0
var _current_map_position:int = 0
@export var _map_fade_curve:Curve

@export var _e:EncounterManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.register_manager.emit(self)
	G.round_new_start.connect(on_round_start_generic)
	#G.round_gameplay_start.connect(on_gameplay_start)
	#G.round_loot_start.connect(on_loot_start)
	_map_spacing = (get_viewport().size.x - _map_position.global_position.x) / (_map_labels.size())
	#call_deferred("initialize")
	
func initialize():
	#_e = GameManager.Encounter
	update_layout()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_content(index:int):
	var encounter = _e._default_encounter
	if (index < _e._encounter_list.size()):
		encounter = _e._encounter_list[index] as GameEncounters
	if !encounter:
		return _e._default_encounter
	else:
		return encounter
	
func update_layout(no_position_update:bool = false):
	var element = _map_labels.pop_front()
	element.global_position.x += 900
	_map_labels.append(element)	
	#_current_map_position += 1
	var goal_position = Vector2.ZERO
	for i in range(_map_labels.size()):
		var e = update_content(i+_current_map_position)
		_map_labels[i].text = e._name
		goal_position = _map_position.global_position
		goal_position.x += _map_spacing * i
		_map_labels[i].modulate.a = _map_fade_curve.sample(float(i) / float(_map_labels.size()))
		SimonTween.start_tween(_map_labels[i],"global_position",goal_position,G.anim_speed_fast,null)

func on_gameplay_start():
	update_layout()

func on_loot_start():
	update_layout()

func on_round_start_generic():
	update_layout()
