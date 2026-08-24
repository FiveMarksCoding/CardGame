extends Control
class_name BattleCardUI

# 卡牌数据
var card_data: CardData

# 卡牌尺寸常量
const BASE_WIDTH: float = 120.0
const BASE_HEIGHT: float = 160.0
const HOVER_SCALE: float = 1.5  # 悬停时放大倍数
var bg_panel: Panel = null

# 状态
var is_selected: bool = false
var is_hovered: bool = false

var _inner: Control;

# 悬停状态切换阈值（相对于放大后的卡牌）
const SWITCH_LEFT_THRESHOLD: float = 0.25
const SWITCH_RIGHT_THRESHOLD: float = 0.8
# 鼠标悬停状态信号
signal hover_entered(card: BattleCardUI);
signal hover_exited(card: BattleCardUI);
# 整体上浮信号
# CardUI.gd 顶部
signal hand_hover_entered();
signal hand_hover_exited();

# ============================================================
# 初始化
# ============================================================
func setup(data: CardData) -> void:
	card_data = data
	custom_minimum_size = Vector2(BASE_WIDTH, BASE_HEIGHT);
	pivot_offset=Vector2(BASE_WIDTH/2,BASE_HEIGHT);
	#中心设在牌下端中间
	_build_visuals();
	#print("CardUI 已添加到场景树，mouse_filter = ", mouse_filter);
	
func _ready ():
	size = Vector2(BASE_WIDTH, BASE_HEIGHT)  # ← 加这一行
	mouse_filter=Control.MOUSE_FILTER_STOP;
	print("CardUI _ready 被调用，mouse_filter=",mouse_filter);
	#print("CardUI _ready 被调用");
# ============================================================
# 视觉构建（纯代码）
# ============================================================
func _build_visuals() -> void:
	#内层容器
	_inner=Control.new();
	_inner.name="InnerContainer";
	_inner.mouse_filter=Control.MOUSE_FILTER_IGNORE;  # 让鼠标事件穿透
	_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	_inner.pivot_offset = Vector2(BASE_WIDTH/2, BASE_HEIGHT)
	add_child(_inner);
	# 背景
	var bg = Panel.new();
	bg.name = "Background";
	var style = StyleBoxFlat.new();
		#检测信号连接到背景上
	bg.mouse_entered.connect(_on_mouse_entered);
	bg.mouse_exited.connect(_on_mouse_exited);
	bg_panel=bg;
	match card_data.card_type:
		"attack":
			style.bg_color = Color(0.9, 0.3, 0.3, 0.9)
		"skill":
			style.bg_color = Color(0.3, 0.5, 0.9, 0.9)
		"power":
			style.bg_color = Color(0.9, 0.7, 0.2, 0.9)
		_:
			style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
			
	# 在 style 设置后面加两行：
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLUE
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inner.add_child(bg)
	
	

	# 卡牌名
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = card_data.card_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.position = Vector2(5, 5)
	name_label.size = Vector2(110, 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	_inner.add_child(name_label)

	# 费用
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.text = str(card_data.cost)
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.position = Vector2(95, 5)
	cost_label.size = Vector2(20, 20)
	cost_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inner.add_child(cost_label)

	# 卡牌类型
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = card_data.card_type
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.position = Vector2(5, 30)
	type_label.size = Vector2(110, 15)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_inner.add_child(type_label)

	# 描述
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = _build_description()
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.position = Vector2(5, 50)
	desc_label.size = Vector2(110, 100)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_inner.add_child(desc_label)

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
	if is_selected: return
	is_selected = true
	z_index = 100

	# 关键：只缩放内层容器，外层节点大小不变
	var tween = create_tween()
	tween.tween_property(_inner, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.1)

func deselect_card() -> void:
	if not is_selected: return
	is_selected = false
	z_index = 0

	var tween = create_tween()
	tween.tween_property(_inner, "scale", Vector2.ONE, 0.1)
# ============================================================
# 鼠标事件
# ============================================================
func _on_mouse_entered() -> void:
	is_hovered = true
	# 通知父节点（手牌容器）当前悬停的是这张牌
	# 父节点会负责处理：放大、散开、切换等
	hover_entered.emit(self);
	#emit(self)表示发射信号，并将自己（本张牌）作为参数发射
	print("鼠标进入了卡牌");
	hand_hover_entered.emit();

func _on_mouse_exited() -> void:
	is_hovered = false
	hover_exited.emit(self);
	print("鼠标离开了卡牌");
	hand_hover_exited.emit();

# ============================================================
# 对外接口（供父节点调用）
# ============================================================
func get_card_data() -> CardData:
	return card_data

func get_selected() -> bool:
	return is_selected

func get_hovered() -> bool:
	return is_hovered
