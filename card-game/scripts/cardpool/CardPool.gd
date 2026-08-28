extends RefCounted;
class_name CardPool;

static var _card_ids: Array[String]=[];

# 初始化卡池（只执行一次）
static func initialize():
	if not _card_ids.is_empty():
		return  # 已经初始化过了
	
	# 测试用牌：12 张，包含不同颜色和费用需求
	_card_ids = [
		# 红色攻击牌
		"strike_red",
		"strike_red_2",
		"heavy_strike",
		# 蓝色攻击牌
		"strike_blue",
		"strike_blue_2",
		# 绿色攻击牌
		"strike_red",
		# 红色防御牌
		"defend_red",
		# 蓝色防御牌
		"defend_blue",
		# 特殊牌
		"double_strike",
		"shield_bash",
		"quick_strike",
		"power_strike",
	]

# 获取随机 N 张卡牌
static func get_random_cards(count: int) -> Array[String]:
	initialize();
	var shuffled=_card_ids.duplicate();
	shuffled.shuffle();
	return shuffled.slice(0,count);
