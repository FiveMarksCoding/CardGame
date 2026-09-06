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
		"special_rule": null,
		"min_nodes_per_row": 4,
		"max_nodes_per_row": 4,
	}
	# 第2层：12层，无BOSS，路径减少50%，休息处×1.5
	layer_configs[2] = {
		"row_count": 12,
		"has_boss": false,
		"special_rule": "path_reduced_rest_boost",
		"path_multiplier": 0.5,
		"rest_chance": 0.15,
		"min_nodes_per_row": 2,
		"max_nodes_per_row": 2,
	}
	# 第3层：10层，有BOSS，菱形网络，50%战斗→商店
	layer_configs[3] = {
		"row_count": 10,
		"has_boss": true,
		"special_rule": "diamond_shop_replacement",
		"diamond_layout": true,
		"shop_replacement_rate": 0.5,
		"min_nodes_per_row": 4,
		"max_nodes_per_row": 5,
	}
	# 第4层：13层，无BOSS，问号×2，商店×0.5
	layer_configs[4] = {
		"row_count": 13,
		"has_boss": false,
		"special_rule": "event_boost_shop_reduced",
		"event_chance_multiplier": 2.0,
		"shop_chance_multiplier": 0.5
	};
	# 第5层：8层，有BOSS，圆形网络
	layer_configs[5] = {
		"row_count": 8,
		"has_boss": true,
		#"special_rule": "circle_network",
		#"circle_layout": true,
		"max_nodes_per_row": 8    # 原来默认是5
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
	# MapManager.gd - get_current_config() 中添加
	if config_data.has("shop_replacement_rate"):
		config.custom_rules["shop_replacement_rate"] = config_data["shop_replacement_rate"]
	# 菱形布局
	if config_data.has("diamond_layout"):
		config.custom_rules["diamond_layout"] = config_data["diamond_layout"]
	# 读取 event_chance 和 shop_chance 的倍数
	if config_data.has("event_chance_multiplier"):
		config.event_chance *= config_data["event_chance_multiplier"];
	if config_data.has("shop_chance_multiplier"):
		config.shop_chance *= config_data["shop_chance_multiplier"];
	if config_data.has("circle_layout"):
		config.custom_rules["circle_layout"]=config_data["circle_layout"];
	if config_data.has("min_nodes_per_row"):
		config.min_nodes_per_row = config_data["min_nodes_per_row"];
	if config_data.has("max_nodes_per_row"):
		config.max_nodes_per_row = config_data["max_nodes_per_row"];
	return config;

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
