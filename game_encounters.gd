class_name GameEncounters extends Resource

enum Type { ENCOUNTER, LOOT, SHOP, INTRO }
enum Rarity { NORMAL, RARE, EPIC }

@export var _type:Type
@export var _rarity:Rarity
@export var _name:String

@export var _enemy:EnemyData
