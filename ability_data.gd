class_name AbilityData extends Resource

enum Type { DAMAGE, BUFF, DEBUFF, WHEEL_DEBUFF, HEAL, SHIELD }
enum Rarity { NORMAL, RARE, EPIC }
enum Target { PLAYER, ENEMY, GLOBAL }

@export var rarity:Rarity

@export var _ability_type:Type
@export var _ability_target:Target
@export var _ability_name:String
@export var _ability_description:String
@export var _ability_icon:Texture
@export var _ability_range:float = 70.0
@export var _magnitude:int

@export var _initial_placement:float

@export var _buff_data:BuffData
