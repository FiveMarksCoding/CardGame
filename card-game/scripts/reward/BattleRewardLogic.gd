extends RefCounted;
class_name BattleRewardLogic;

enum State {
	PENDING,      # 待处理
	CLAIMED,      # 已全部领取
	DEFERRED      # 稍后处理
}
# 奖励列表
var rewards: Array[RewardData]=[];
# 当前状态
var state: State=State.PENDING;
# 卡牌奖励数量
var card_reward_count: int=3;
# 奖励卡牌组
var card_groups: Array = []  # 存储每组卡牌的索引范围

# BattleRewardLogic.gd - 删除 generate_rewards() 函数
# 新增 initialize() 函数

func initialize (rewards_array: Array[RewardData]):
	rewards=rewards_array;
	state=State.PENDING;
	_build_card_groups()  # 自动构建组索引
func _build_card_groups ():
	card_groups.clear();
	var group_start=-1;
	for i in range(rewards.size()):
		var r=rewards[i];
		if r.type==RewardData.Type.CARD:
			if group_start==-1:
				group_start=i;
		else:
			if group_start!=-1:
				card_groups.append({"start":group_start,"end":i-1});
				group_start=-1
	# 如果最后一批是卡牌
	if group_start!=-1:
		card_groups.append({"start": group_start, "end": rewards.size() - 1})
# 领取单个奖励
func claim_reward(index: int) -> bool:
	if (index<0) || (index>=rewards.size()):
		return 0;
	var reward=rewards[index];
	if reward.is_claimed:
		return 0;
	
	reward.is_claimed=1;
	# 实际应用奖励（稍后实现）
	# _apply_reward(reward)
	
	# 检查是否所有奖励都已领取
	var all_claimed=1;
	for r in rewards:
		if !r.is_claimed:
			all_claimed=0;
			break;
	if all_claimed:
		state=State.CLAIMED
	return 1;
# 稍后处理
func defer():
	state = State.DEFERRED
# 是否已领取
func is_completed() -> bool:
	return state==State.CLAIMED;
# 获取所有卡牌奖励的ID列表（供UI显示）
func get_card_rewards() -> Array[String]:
	var ids: Array[String]=[];
	for i in rewards:
		if (i.type==RewardData.Type.CARD) && (!i.is_claimed):
			ids.append(i.card_id);
	return ids;
# 清空所有未领取的奖励
func discard_pending_rewards():
	rewards.clear();
	state=State.CLAIMED;
func get_gold_amount() -> int:
	for i in rewards:
		if (i.type==RewardData.Type.GOLD) && (!i.is_claimed):
			return i.gold_amount;
	return 0;
# 是否还有未领取的奖励
func has_unclaimed() -> bool:
	for r in rewards:
		if not r.is_claimed:
			return true
	return false
# 是否还有未领取的卡牌奖励
func has_unclaimed_cards() -> bool:
	for r in rewards:
		if r.type == RewardData.Type.CARD and not r.is_claimed:
			return 1;
	return 0;
