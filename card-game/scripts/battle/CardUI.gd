extends Control
class_name BattleCardUI

# 卡牌数据
var card_data: CardData

# 卡牌尺寸常量
const BASE_WIDTH: float = 120.0
const BASE_HEIGHT: float = 160.0
const HOVER_SCALE: float = 2.0  # 悬停时放大倍数

# 状态
var is_selected: bool = false
var is_hovered: bool = false

# 悬停状态切换阈值（相对于放大后的卡牌）
const SWITCH_LEFT_THRESHOLD: float = 0.25
const SWITCH_RIGHT_THRESHOLD: float = 0.8

# ============================================================
# 初始化
# ============================================================
func setup(data: CardData) -> void:
	card_data = data
	custom_minimum_size = Vector2(BASE_WIDTH, BASE_HEIGHT)
	_build_visuals()

# ============================================================
# 视觉构建（纯代码）
# ============================================================
func _build_visuals() -> void:
	# 背景
	var bg = Panel.new()
	bg.name = "Background"
	var style = StyleBoxFlat.new()
	match card_data.card_type:
		"attack":
			style.bg_color = Color(0.9, 0.3, 0.3, 0.9)
		"skill":
			style.bg_color = Color(0.3, 0.5, 0.9, 0.9)
		"power":
			style.bg_color = Color(0.9, 0.7, 0.2, 0.9)
		_:
			style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 卡牌名
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = card_data.card_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.position = Vector2(5, 5)
	name_label.size = Vector2(110, 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(name_label)

	# 费用
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.text = str(card_data.cost)
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.position = Vector2(95, 5)
	cost_label.size = Vector2(20, 20)
	cost_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(cost_label)

	# 卡牌类型
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = card_data.card_type
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.position = Vector2(5, 30)
	type_label.size = Vector2(110, 15)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(type_label)

	# 描述
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = _build_description()
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.position = Vector2(5, 50)
	desc_label.size = Vector2(110, 100)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(desc_label)

func _build_description() -> String:
	var parts = []
	if card_data.damage > 0:
		parts.append("造成 %d 伤害" % card_data.damage)
	if card_data.block > 0:
		parts.append("获得 %d 格挡" % card_data.block)
	if card_data.needs_target:
		parts.append("需要目标")
	return "\n".join(parts)

# ============================================================
# 选中 / 取消选中
# ============================================================
func select_card() -> void:
	if is_selected:
		return
	is_selected = true
	z_index = 100
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.1)

func deselect_card() -> void:
	if not is_selected:
		return
	is_selected = false
	z_index = 0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

# ============================================================
# 鼠标事件
# ============================================================
func _on_mouse_entered() -> void:
	is_hovered = true
	# 通知父节点（手牌容器）当前悬停的是这张牌
	# 父节点会负责处理：放大、散开、切换等

func _on_mouse_exited() -> void:
	is_hovered = false

# ============================================================
# 对外接口（供父节点调用）
# ============================================================
func get_card_data() -> CardData:
	return card_data

func get_selected() -> bool:
	return is_selected

func get_hovered() -> bool:
	return is_hovered

# ============================================================
# 位置检测（供父节点做切换判断）
# ============================================================
func get_switch_direction() -> int:
	#"""
	#检测鼠标在放大后的卡牌上的相对位置
	#返回: -1 (向左切换), 0 (不切换), 1 (向右切换)
	#"""
	var local_pos = get_local_mouse_position()
	var w = size.x * scale.x
	if local_pos.x < w * SWITCH_LEFT_THRESHOLD:
		return -1
	elif local_pos.x > w * SWITCH_RIGHT_THRESHOLD:
		return 1
	return 0

func is_mouse_above_card() -> bool:
	#"""检测鼠标是否在当前卡牌上方（用于判断是否离开手牌区）"""
	var local_pos = get_local_mouse_position()
	var h = size.y * scale.y
	return local_pos.y < 0 or local_pos.y > h
