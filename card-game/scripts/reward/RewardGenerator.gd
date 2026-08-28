extends RefCounted;
class_name RewardGenerator;

# 生成奖励列表
static func generate (battle_type: String) -> Array[RewardData]:
	var rewards: Array[RewardData]=[];
	# 卡牌奖励
	# 普通战斗 1 组三选一，精英战斗 2 组
	var group_count=1 if battle_type!="elite"  else 2;
	for g in range(group_count):
		var ids=CardPool.get_random_cards(3);  # 三选一
		for i in ids:
			rewards.append(RewardData.create_card(i));
	# 金币奖励
	var gold=0;
	match battle_type:
		"normal":
			gold = randi_range(50, 70);
		"elite":
			gold = randi_range(100, 120);
		"boss":
			gold = randi_range(150, 200);
		_:
			gold=50;
	rewards.append(RewardData.create_golds(gold));
	return rewards
