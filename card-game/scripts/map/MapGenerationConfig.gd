extends RefCounted;
class_name MapGenerationConfig;

var row_count: int=8;                    # 总行数（小层数）
var has_boss: bool=0;               # 是否有BOSS
var boss_row_offset: int=-2;            # BOSS所在行（相对于总行数）
var has_jump: bool=1;                # 是否有跳转层
var jump_row_offset: int=-1;            # 跳转层所在行
var min_jump_nodes: int=2;              # 跳转层最少节点数
var max_jump_nodes: int=2;              # 跳转层最多节点数
# 节点数量控制
var min_nodes_per_row: int=3
var max_nodes_per_row: int=5;
# 节点类型概率
var battle_chance: float=0.4;
var elite_chance: float=0.15;
var shop_chance: float=0.1;
var rest_chance: float=0.1;
var event_chance: float=0.25;
# 特殊规则
var custom_rules: Dictionary={};

func _init (p_row_count: int=8,p_has_boss: bool=0):
	row_count=p_row_count;
	has_boss=p_has_boss;
func apply_special_rule ():
	var rule = custom_rules.get("special_rule", "")
	match rule:
		"path_reduced_rest_boost":
			# 路径减少50%：由 StandardMapGenerator 读取 path_multiplier
			# 休息处×1.5：修改 rest_chance
			rest_chance = custom_rules.get("rest_chance", rest_chance)
		_:
			pass
