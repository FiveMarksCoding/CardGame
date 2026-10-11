extends RefCounted;
class_name CardResolver;
# 曾用名 CES
static func resolve (card_data: CardData, target: Enemy, logic: BattleLogic) -> Dictionary:
	var result={"damage": 0, "block": 0};
	# 伤害
	if card_data.damage>0 && target:
		target.take_damage(card_data.damage);
		result["damage"]=card_data.damage;
	# 格挡
	if card_data.block>0:
		logic.add_block(card_data.block);
		result["block"]=card_data.block;
	return result;
