extends CanvasLayer;
class_name BattleRewardUI;

signal reward_completed();
signal reward_deferred();

var _logic: BattleRewardLogic = null
var _current_group_index: int = 0  # 当前打开的卡牌组索引
var _is_sub_ui_open: bool = false

# 主界面节点
var _main_panel: Panel = null
var _main_container: VBoxContainer = null
var _card_selector_btn: Button = null
var _gold_btn: Button=null;
var go_to_map_btn: Button=null;
# 子界面节点
var _sub_panel: Panel = null
var _sub_container: VBoxContainer = null
var _card_container: HBoxContainer = null
var _skip_btn: Button = null
## 基本函数
func _ready():
	visible=0;
	# 确保 CanvasLayer 在最高层
	layer=10;
func show_rewards(logic: BattleRewardLogic) -> void:
	_logic=logic;
	_current_group_index=0;
	_is_sub_ui_open=0;
	_build_main_ui();
	_build_sub_ui();
	_update_main_ui();
	visible=1;
## UI 构建 
func _build_main_ui() -> void:
	# 全屏遮罩
	var bg=ColorRect.new();
	bg.color=Color(0,0,0,0.7);
	bg.size=get_viewport().get_visible_rect().size;  # 用 get_visible_rect() 确保全屏
	bg.mouse_filter=Control.MOUSE_FILTER_STOP;
	bg.anchors_preset=Control.PRESET_FULL_RECT;
	add_child(bg);
	# 主面板
	_main_panel=Panel.new();
	_main_panel.size=Vector2(400,500);
	_main_panel.position=(get_viewport().get_visible_rect().size-_main_panel.size)/2;
	_main_panel.mouse_filter=Control.MOUSE_FILTER_STOP;
	add_child(_main_panel);
	# 容器
	_main_container=VBoxContainer.new();
	_main_container.anchors_preset=Control.PRESET_FULL_RECT;  # 填满父面板
	_main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	_main_container.offset_left=20.0;
	_main_container.offset_right=-20.0;
	_main_container.offset_top=20.0;
	_main_container.offset_bottom=-20.0;
	_main_container.alignment=BoxContainer.ALIGNMENT_BEGIN;
	_main_panel.add_child(_main_container);
	# 标题
	var title=Label.new();
	title.text="战斗胜利！";
	title.add_theme_font_size_override("font_size",28);
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;
	_main_container.add_child(title);
	# 卡牌选择按钮;
	_card_selector_btn=Button.new();
	_card_selector_btn.text="选择一张卡牌";
	_card_selector_btn.size = Vector2(300,70);
	_card_selector_btn.pressed.connect(_on_card_selector_pressed)
	_main_container.add_child(_card_selector_btn)
	# 金币按钮
	_gold_btn = Button.new()
	_gold_btn.text = "金币 +0"
	_gold_btn.size = Vector2(300, 70)
	_gold_btn.pressed.connect(_on_gold_pressed)
	_main_container.add_child(_gold_btn);
	# 前往地图 gogogo
	var go_to_map_btn = Button.new()
	go_to_map_btn.text = "前往地图"
	go_to_map_btn.custom_minimum_size = Vector2(140, 50)
	go_to_map_btn.position = Vector2(
	_main_panel.size.x-160,
	_main_panel.size.y-70
	);
	go_to_map_btn.pressed.connect(_on_go_to_map_pressed);
	_main_panel.add_child(go_to_map_btn)
func _build_sub_ui() -> void:
	# 子面板（与主面板重叠）
	_sub_panel = Panel.new()
	_sub_panel.size = Vector2(800, 500)
	_sub_panel.position = (get_viewport().get_visible_rect().size - _sub_panel.size) / 2
	_sub_panel.visible = false
	_sub_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_sub_panel)
	# 子容器
	_sub_container=VBoxContainer.new()
	_sub_container.size=Vector2(760,460);
	_sub_container.position=Vector2(20,20);
	_sub_container.alignment=BoxContainer.ALIGNMENT_CENTER;
	_sub_panel.add_child(_sub_container);
	# 标题
	var sub_title = Label.new()
	sub_title.text = "选择一张卡牌"
	sub_title.add_theme_font_size_override("font_size", 24)
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_container.add_child(sub_title)
	# 卡牌横向容器(子容器的子容器)
	_card_container=HBoxContainer.new()
	_card_container.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;
	_sub_container.add_child(_card_container);
	# 跳过按钮
	_skip_btn=Button.new();
	_skip_btn.text="跳过"
	_skip_btn.custom_minimum_size=Vector2(120,60);
	_skip_btn.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;
	_skip_btn.pressed.connect(_on_skip_pressed);
	_sub_container.add_child(_skip_btn);

# ============ UI 更新 ============

func _update_main_ui() -> void:
	if !_logic:
		return
	# 检查当前组是否还有未领取的卡牌
	var has_current_group_cards = _has_unclaimed_in_current_group()
	_card_selector_btn.visible = has_current_group_cards
	_card_selector_btn.disabled = not has_current_group_cards

	# 金币
	var gold = _logic.get_gold_amount()
	_gold_btn.visible = gold > 0
	if gold > 0:
		_gold_btn.text = "金币 +%d" % gold
		_gold_btn.disabled = false

func _has_unclaimed_in_current_group() -> bool:
	if _current_group_index >= _logic.card_groups.size():
		return false
	var group = _logic.card_groups[_current_group_index]
	for i in range(group.start, group.end + 1):
		if i < _logic.rewards.size() and not _logic.rewards[i].is_claimed:
			return true
	return false

func _show_sub_ui() -> void:
	_main_panel.visible=0;
	_sub_panel.visible=1;
	_is_sub_ui_open=1;
	for i in _card_container.get_children():
		i.queue_free();
		
	_card_container.alignment=BoxContainer.ALIGNMENT_CENTER  # 整体居中
	_card_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL  # 填满宽度
	# 显示当前组的卡牌
	var group = _logic.card_groups[_current_group_index]
	for i in range(group.start, group.end + 1):
		var reward = _logic.rewards[i]
		if reward.is_claimed:
			continue
		var card_data = _get_card_data_by_id(reward.card_id)
		if card_data == null:
			continue
		var card_ui = BattleCardUI.new()
		card_ui.setup(card_data)
		card_ui.scale = Vector2(0.8, 0.8)
		card_ui.card_clicked.connect(_on_card_ui_clicked.bind(i));
		card_ui.custom_minimum_size=Vector2(120,160)
		card_ui.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_ui.hover_entered.connect(_on_reward_card_hover);
		card_ui.hover_exited.connect(_on_reward_card_unhover);
		_card_container.add_child(card_ui);
		if i<group.end:
			var spacer=Control.new();
			spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;
			_card_container.add_child(spacer);
func _hide_sub_ui ():
	#await get_tree().create_timer(0.5).timeout;
	_sub_panel.visible=0;
	_main_panel.visible=1;
	_is_sub_ui_open=0;
	_update_main_ui()
# ============ 信号处理 ============
# 点击选牌按钮
func _on_card_selector_pressed() -> void:
	if _has_unclaimed_in_current_group():
		_show_sub_ui()
# 点牌
func _on_card_ui_clicked(card: BattleCardUI, index: int) -> void:
	if !_logic:
		return;
	var s=_logic.claim_reward(index)
	if !s:
		return;
	var _pos=card.global_position;
	# 先把卡牌从容器中移除（但保留在场景中）
	var p=card.get_parent();
	if p:
		p.remove_child(card);
	# 添加到根节点（或当前场景）
	var root=self;
	if root:
		root.add_child(card);
		card.global_position=_pos;  # 保持位置
		card.z_index=101;
	# 关闭子界面
	_hide_sub_ui();
	# 播放动画
	card.set_interactive(0);
	_fly_to_top_left(card);
	# 等待动画,移动下一组
	await get_tree().create_timer(0.3).timeout;
	_current_group_index+=1;
	if _logic.is_completed():
		_on_all_claimed();
	else:
		_update_main_ui();
# 奖励界面卡牌悬停放大
func _on_reward_card_hover(card: BattleCardUI) -> void:
	# 放大到 1.2 倍（配合外层 0.8 倍缩放，实际显示 1 倍）
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(card._inner,"scale",Vector2(1.2,1.2),0.1)
# 奖励界面卡牌悬停取消
func _on_reward_card_unhover(card: BattleCardUI) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(card._inner, "scale", Vector2(1.0, 1.0), 0.1)
# 跳过选牌
func _on_skip_pressed ():
	_hide_sub_ui();
# 领取金币
func _on_gold_pressed ():
	if !_logic:
		return
	var s=_logic.claim_reward(_logic.rewards.size()-1);
	if !s:
		return;
	_gold_btn.disabled=1;
	_fly_to_top_left(_gold_btn,0);
	await get_tree().create_timer(0.3).timeout
	_gold_btn.visible=0;
	if _logic.is_completed():
		_on_all_claimed();
	else:
		_update_main_ui();
# 点击按钮前往地图
func _on_go_to_map_pressed() -> void:
	# 暂时只关闭界面，不实现跳转
	# 等地图系统接入后，再连接实际跳转逻辑
	visible = false
	# 通知上层（BattleManager）奖励界面已关闭
	reward_completed.emit()  # 复用这个信号，表示“关闭界面”
# 废案
func _on_all_claimed() -> void:
	visible=0;
	reward_completed.emit();
## 工具函数
func _fly_to_top_left(node: Control, should_free: bool = true) -> void:
	var end_pos = Vector2(50, 50)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(node, "global_position", end_pos, 0.3)
	tween.parallel().tween_property(node, "scale", Vector2(0.3, 0.3), 0.3)
	tween.parallel().tween_property(node, "modulate", Color(1, 1, 1, 0), 0.3)
	if should_free:
		tween.tween_callback(node.queue_free)
	else:
		tween.tween_callback(func(): node.modulate = Color(1, 1, 1, 0))
# 临时
func _get_card_data_by_id(id: String) -> CardData:
	for card in GameState.player_deck:
		if card.id == id:
			return card
	var temp_data = CardData.new()
	temp_data.id = id
	temp_data.card_name = id.replace("_", " ").capitalize()
	temp_data.card_type = "attack" if id.contains("strike") else "skill"
	temp_data.damage = 5
	temp_data.block = 0
	temp_data.needs_target = true
	return temp_data
