extends RefCounted;
class_name Intent;
enum Type {
	ATTACK,
	DEFEND,
	BUFF,
	DEBUFF,
	HEAL,
	SPECIAL,
};

var type: Type;
var value: int;
var times: int;
func _init (x1: Type,x2: int,x3: int,):
	type=x1;
	value=x2;
	times=x3;
func get_description() -> String:
	match type:
		Type.ATTACK:
			return "造成 %d 伤害 %d 次" % [value, times] if times > 1 else "造成 %d 伤害" % value
		Type.DEFEND:
			return "防御 %d" % value
		Type.BUFF:
			return "力量+%d" % value
		Type.DEBUFF:
			return "虚弱 %d" % value
		Type.HEAL:
			return "治疗 %d" % value
		Type.SPECIAL:
			return "特殊"
		_:
			return "未知"
