extends RefCounted;
class_name RewardData;

enum Type {
	CARD,
	GOLD,
	# 以后可以加 RELIC, POTION
};
var type: Type;
var card_id: String;       # 仅当 type == CARD 时有效
var gold_amount: int;      # 仅当 type == GOLD 时有效
var is_claimed: bool=0;
static func create_cards (id: String) -> RewardData:
	var x=RewardData.new();
	x.type=Type.CARD;
	x.card_id=id;
	return x;
static func create_golds (n: int) -> RewardData:
	var x=RewardData.new();
	x.type=Type.GOLD;
	x.gold_amount=n;
	return x;
