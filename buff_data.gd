class_name BuffData extends Resource

enum Type { DAMAGE_UP, DAMAGE_REDUCTION }
@export var type:Type
@export var name:String = ""
@export var description:String = ""
@export var duration:int = 5
@export var magnitude:float = 2.0
@export var texture:Texture
