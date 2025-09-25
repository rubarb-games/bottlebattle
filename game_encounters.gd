class_name GameEncounters extends Resource

enum Type { ENCOUNTER, LOOT, SHOP }
enum Rarity { NORMAL, RARE, EPIC }

@export var _type:Type
@export var _rarity:Rarity
