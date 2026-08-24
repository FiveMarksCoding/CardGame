## 这个文件是一个大 struct
class_name CardData 
extends RefCounted

var id: String
var card_name: String
var cost: int
var card_type: String  # "attack", "skill", "power"
var damage: int
var block: int
var needs_target: bool   # 1 = yes，0 = no
var description: String

func _init(
	p_id: String = "",
	p_name: String = "",
	p_cost: int = 0,
	p_type: String = "attack",
	p_damage: int = 0,
	p_block: int = 0,
	p_needs_target: bool = 0,
	p_desc: String = ""
):
	id = p_id
	card_name = p_name
	cost = p_cost
	card_type = p_type
	damage = p_damage
	block = p_block
	needs_target = p_needs_target
	description = p_desc
