extends Node
# 全局已加载

# 单例引用（方便全局访问）
static var instance=null;
# 当前所在大层（1-7）
var current_layer: int = 1
# 当前层的地图数据
var current_map_data: MapData = null
# 各层配置（预设）
var layer_configs: Dictionary = {}
func _ready():
	instance = self
	_init_layer_configs()

func _init_layer_configs():
	# 第1层：标准8层，无BOSS
	layer_configs[1] = {
		"row_count": 8,
		"has_boss": false,
		"special_rule": null
	}
	# 第2层：12层，无BOSS，路径减少50%，休息处×1.5
	layer_configs[2] = {
		"row_count": 12,
		"has_boss": false,
		"special_rule": "path_reduced_rest_boost",
		"path_multiplier": 0.5,
		"rest_chance": 0.15
	}
	# 第3层：10层，有BOSS，菱形网络，50%战斗→商店
	layer_configs[3] = {
		"row_count": 10,
		"has_boss": true,
		"special_rule": "diamond_shop_replacement"
	}
	# 第4层：13层，无BOSS，问号×2，商店×0.5
	layer_configs[4] = {
		"row_count": 13,
		"has_boss": false,
		"special_rule": "event_boost_shop_reduced"
	}
	# 第5层：8层，有BOSS，圆形网络
	layer_configs[5] = {
		"row_count": 8,
		"has_boss": true,
		"special_rule": "circle_network"
	}
	# 第6层：15层，有BOSS，三条独立路径
	layer_configs[6] = {
		"row_count": 15,
		"has_boss": true,
		"special_rule": "three_independent_paths"
	}
	# 第7层：4层，有BOSS，四节点
	layer_configs[7] = {
		"row_count": 4,
		"has_boss": true,
		"special_rule": "four_nodes"
	}
# 获取当前层的配置
func get_current_config() -> MapGenerationConfig:
	var config_data = layer_configs.get(current_layer)
	if config_data == null:
		return MapGenerationConfig.new(8, false)
	
	var config = MapGenerationConfig.new(
		config_data["row_count"],
		config_data["has_boss"]
	)
	
	# 应用特殊规则
	var rule = config_data.get("special_rule")
	if rule != null:
		config.custom_rules["special_rule"] = rule
	
	# 读取路径倍数（如果有）
	if config_data.has("path_multiplier"):
		config.custom_rules["path_multiplier"] = config_data["path_multiplier"]
	
	# 读取 rest_chance（如果有）← 新增
	if config_data.has("rest_chance"):
		config.rest_chance = config_data["rest_chance"]
	
	return config

# 生成当前层地图
func generate_current_map() -> MapData:
	var config = get_current_config()
	var generator = StandardMapGenerator.new()
	current_map_data = generator.generate(config)
	return current_map_data

# 进入下一层
func go_to_next_layer() -> void:
	if current_layer < 7:
		current_layer += 1
		generate_current_map()
	else:
		print("已到达最后一层！")

# 重置到第1层
func reset_to_first_layer() -> void:
	current_layer = 1
	generate_current_map()
