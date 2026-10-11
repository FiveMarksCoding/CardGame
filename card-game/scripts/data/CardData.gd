extends Resource;
class_name CardData;

@export var id: String="";
@export var card_name: String="";
@export var cost: int=0;
@export var card_type: String="attack";   # "attack", "skill", "power"
@export var damage: int=0;
@export var block: int=0;
@export var needs_target: bool=0;
@export var description: String="";
@export var card_color: String="neutral"  # "neutral", "red", "blue", "green", "purple", "yellow"
@export var energy_re: Array=[];

## Temp
# 兼容旧的构造方式，CardLibrary 建好后会移除
func _init(
	p_id: String = "",
	p_name: String = "",
	p_cost: int = 0,
	p_type: String = "attack",
	p_damage: int = 0,
	p_block: int = 0,
	p_needs_target: bool = false,
	p_desc: String = "",
	p_color: String = "neutral",
	p_re: Array = []
):
	id = p_id
	card_name = p_name
	cost = p_cost
	card_type = p_type
	damage = p_damage
	block = p_block
	needs_target = p_needs_target
	description = p_desc
	card_color = p_color
	energy_re = p_re
