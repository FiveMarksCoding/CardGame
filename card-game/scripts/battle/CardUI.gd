extends Control;
class_name BattleCardUI;

# 卡牌数据
var card_data: CardData;

# 卡牌尺寸常量
const BASE_WIDTH: float=120.0;
const BASE_HEIGHT: float=160.0;
const HOVER_SCALE: float=1.5;  # 悬停时放大倍数

# 状态
var is_selected: bool=0;
var is_hovered: bool=0;
#卡牌使用双层 Control,外层负责交互，内层负责渲染
var _inner: Control;
# 碰撞箱
var hitbox: ColorRect;
# 鼠标悬停状态信号
signal hover_entered(card: BattleCardUI);
signal hover_exited(card: BattleCardUI);
# 整体上浮信号
signal hand_hover_entered();
signal hand_hover_exited();
# 拖拽
# CardUI.gd - 在信号区域添加
signal drag_started(card: BattleCardUI,mouse_pos: Vector2);
signal drag_ended(card: BattleCardUI,mouse_pos: Vector2);
signal drag_moved(card: BattleCardUI,mouse_pos: Vector2);
var is_dragging: bool=0;
var drag_start: Vector2=Vector2.ZERO;
# 卡牌渲染。临时
func _build_visuals() -> void:
	#内层容器
	_inner=Control.new();
	_inner.name="InnerContainer";
	_inner.mouse_filter=Control.MOUSE_FILTER_IGNORE;  # 让鼠标事件穿透
	_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	_inner.pivot_offset = Vector2(BASE_WIDTH/2, BASE_HEIGHT);
	add_child(_inner);
	# 背景
	var bg=Panel.new();
	bg.name="Background";
	var style=StyleBoxFlat.new();
	match card_data.card_type:
		"attack":
			style.bg_color = Color(0.9, 0.3, 0.3, 0.9)
		"skill":
			style.bg_color = Color(0.3, 0.5, 0.9, 0.9)
		"power":
			style.bg_color = Color(0.9, 0.7, 0.2, 0.9)
		_:
			style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	# 边框		
	style.border_width_left=2;
	style.border_width_right=2;
	style.border_width_top=2;
	style.border_width_bottom=2;
	style.border_color=Color.BLUE;
	bg.add_theme_stylebox_override("panel", style);
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	_inner.add_child(bg);
	# 卡牌名
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = card_data.card_name;
	name_label.add_theme_font_size_override("font_size", 14);
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
#描述单独处理
func _build_description() -> String:
	var parts = [];
	#parts.append("1111111111111111111111111111111111");
	if card_data.damage > 0:
		parts.append("造成 %d 伤害" % card_data.damage)
	if card_data.block > 0:
		parts.append("获得 %d 格挡" % card_data.block)
	if card_data.needs_target:
		parts.append("需要目标")
	return "\n".join(parts)
# 初始化
func setup(data: CardData) -> void:
	card_data=data;
	custom_minimum_size = Vector2(BASE_WIDTH, BASE_HEIGHT);
	pivot_offset=Vector2(BASE_WIDTH/2,BASE_HEIGHT);
	#中心设在牌下端中间
	_build_visuals();
	#print("CardUI 已添加到场景树，mouse_filter = ", mouse_filter);
func _ready ():
	size=Vector2(BASE_WIDTH,BASE_HEIGHT);  
	mouse_filter=Control.MOUSE_FILTER_STOP;
	# 卡牌碰撞箱
	hitbox=ColorRect.new()
	hitbox.name="hitbox";
	hitbox.color=Color(0,0,0,0); 
	hitbox.size=Vector2(BASE_WIDTH,BASE_HEIGHT);
	hitbox.mouse_filter=Control.MOUSE_FILTER_STOP;
	add_child(hitbox);
	# 信号
	hitbox.mouse_entered.connect(_on_mouse_entered);
	hitbox.mouse_exited.connect(_on_mouse_exited);
	hitbox.gui_input.connect(_on_hitbox_gui_input)
	#print("CardUI _ready 被调用，mouse_filter=",mouse_filter);
	#print("CardUI _ready 被调用");
# 通过节点名称查找 hitbox
func set_interactive(enabled: bool):
	for i in get_children():
		if (i is ColorRect) && (i.name == "hitbox"):
			i.mouse_filter=Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE;
			break;
# 选中 / 取消选中
func select_card() -> void:
	if is_selected: 
		return;
	is_selected=1;
	#z_index=100;
	#只缩放内层容器，外层节点大小不变
	var tween=create_tween();
	tween.tween_property(_inner,"scale",Vector2(HOVER_SCALE, HOVER_SCALE),0.1);
func deselect_card() -> void:
	if not is_selected: 
		return;
	is_selected=0;
	#z_index=0;
	var tween=create_tween();
	tween.tween_property(_inner,"scale",Vector2.ONE,0.1);
# 鼠标事件
func _on_mouse_entered() -> void:
	is_hovered = true
	# 通知父节点（手牌容器）当前悬停的是这张牌
	# 父节点会负责处理：放大、散开、切换等
	hover_entered.emit(self);
	hand_hover_entered.emit();
	#emit(self)表示发射信号，并将自己（本张牌）作为参数发射
	#print("鼠标进入了卡牌");
func _on_mouse_exited() -> void:
	is_hovered = false
	hover_exited.emit(self);
	hand_hover_exited.emit();
	#print("鼠标离开了卡牌");
# 对外接口（供父节点调用）
func get_card_data() -> CardData:
	return card_data
func get_selected() -> bool:
	return is_selected
func get_hovered() -> bool:
	return is_hovered
# 飞向目标。中国人能飞
func fly_to (pos1:Vector2,time: float=0.3,callback: Callable=Callable()):
	var tree=get_tree();
	if !tree:
		print("fly_to: 树不存在，无法继续");
		return;
	var p=get_parent();
	var current_global=global_position  # 记录当前位置
	if p:
		p.remove_child(self);
	tree.root.add_child(self);
	global_position=current_global;  # 恢复位置
	var tween=create_tween();
	tween.set_ease(Tween.EASE_OUT);
	tween.set_trans(Tween.TRANS_QUINT);
	tween.tween_property(self,"global_position",pos1,time);
	if callback!=Callable():
		tween.tween_callback(callback);
# 拖拽
func _on_hitbox_gui_input(event: InputEvent):
	if (event is InputEventMouseButton) && (event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			is_dragging=1;
			drag_start=get_global_mouse_position();
			drag_started.emit(self,drag_start);
			var tween=create_tween();
			tween.tween_property(_inner,"scale",Vector2(1.1, 1.1),0.1);
		else:
			if is_dragging:
				var pos=get_global_mouse_position();
				var hand_container=get_parent();
				if hand_container && hand_container.has_method("try_play_card"):
					hand_container.try_play_card(self,pos);
				drag_ended.emit(self,pos);
				is_dragging=0;
func _process(delta: float):
	if is_dragging:
		global_position=get_global_mouse_position()-(size/2);   # 卡牌跟随鼠标
		drag_moved.emit(self,get_global_mouse_position());
# 弃牌动画
# 弃牌后子节点先销毁，需要单独动画
func play_discard_animation() -> void:
	var end_pos=global_position+Vector2(200, 0);
	var tween=create_tween();
	tween.set_ease(Tween.EASE_IN);
	tween.tween_property(self,"global_position",end_pos,0.15);
	tween.parallel().tween_property(self, "modulate",Color(1,1,1,0),0.15);
