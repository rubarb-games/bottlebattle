class_name Bottle extends Resource

enum Rarity { NORMAL, RARE, EPIC }
@export var rarity:Rarity

@export var name:String = ""
@export var description:String = ""

@export var max_bottle_abilities:int = 3

@export var arc_range:float = 25.0
@export var crit_multiplier:float = 1.5
@export var crit_range:float = 5.0
@export var bottle_texture:Texture
