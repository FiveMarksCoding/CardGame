extends RefCounted;
class_name EnemyData;

var id: String;
var name: String;
var current_hp: int;
var max_hp: int;
var intent_pool: Array=[];

func _init (x1: String,x2: String,x3: int,x4: Array=[]):
	id=x1;
	name=x2;
	current_hp=x3;
	max_hp=x3;
	intent_pool=x4;

func get_intent_group() -> Array:
	# 从意图池中随机选一组（简单实现：直接取第一个）
	if intent_pool.is_empty():
		return [];
	return intent_pool[randi()%intent_pool.size()].duplicate()
