extends Control;
class_name HandContainer;

var hands: Array[BattleCardUI]=[];
var base_positions: Array[Vector2] = []  # 存储每张牌的基准位置
# 布局参数
const ARC_HEIGHT: float=10.0;       # 弧高，中间牌最高
const MAX_CARD_SPACING: float=-40;  # 负值 = 重叠
const ROT_MAX: float=0.17;           # 最大旋转弧度 (约 11.5°)
const CARD_WIDTH: float=120.0
const CARD_HEIGHT: float=160.0;
const CARD_SPACING: float=10.0;
const HOVER_UP_OFFSET: float=-60.0;  # 上移距离（负值表示向上）
const CARD_y: int=30;
const SCATTER_OFFSET_LEFT = 60.0
const SCATTER_OFFSET_RIGHT = 90.0
#左右撤退距离
var hover_count: int = 0
var exit_timer: float = 0.0  # 延迟计时器
const EXIT_DELAY: float = 0.3  # 延迟时间（秒）
#计时防抖
var is_hovering: bool=0;  # 是否在手牌区域内
var current_y_offset: float = 0.0
var current_x_offsets: Array[float] = []  # 每张牌独立的水平偏移

func _ready ():
	#mouse_entered.connect(_on_mouse_entered);
	#mouse_exited.connect(_on_mouse_exited);
	mouse_filter=Control.MOUSE_FILTER_IGNORE;
	#HandContainer 不应该拦截鼠标事件
	hover_count = 0;
	current_x_offsets=[];
	for i in range(hands.size()):
		current_x_offsets.append(0.0);
	_add_test_cards();
func _add_test_cards ():
	var copydeck=GameState.player_deck;
	for i in range(min(5,copydeck.size())):
		var card_data=copydeck[i];
		var card_ui=BattleCardUI.new();
		card_ui.setup(card_data);
		card_ui.hover_entered.connect(_on_card_hover_entered);
		card_ui.hover_exited.connect(_on_card_hover_exited);
		card_ui.hand_hover_entered.connect(_on_hand_hover_entered)
		card_ui.hand_hover_exited.connect(_on_hand_hover_exited)
		add_child(card_ui);
		hands.append(card_ui);
	_arrange_cards();
func _arrange_cards ():
	var n=hands.size();
	if n==0:
		return;
	base_positions.clear()
	# 计算总宽度 (使用重叠)
	var total_width=n*CARD_WIDTH+(n-1)*MAX_CARD_SPACING;
	var start_x=(size.x-total_width)/2.0;
	var y_offset=CARD_y;  # 你之前调整的基准 Y 偏移
	for i in range(n):
		var card=hands[i];
		# 1. 计算归一化位置 [-1, 1]
		var t: float;
		if n==1:
			t=0.0;
		else:
			t=(float(i)/float(n-1))*2.0-1.0;       
		# 2. 计算 X 位置 (水平重叠)
		var x = start_x + i * (CARD_WIDTH + MAX_CARD_SPACING)
		# 3. 计算 Y 位置 (弧高，中间牌最高)
		var arc_offset = -ARC_HEIGHT * (t * t) + ARC_HEIGHT
		var y = y_offset - arc_offset  # arc_offset 为正，所以向上偏移
		# 4. 计算旋转角度
		var rot = t * ROT_MAX
		
		# 5. 应用位置和旋转
		var pos = Vector2(x, y)
		card.position = pos
		card.rotation = rot
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		base_positions.append(pos)	
	print("卡牌位置: ", hands[0].position, "  容器大小: ", size);
func _calculate_rotation(index: int, total: int) -> float:
	if total <= 1:
		return 0.0
	# 将索引映射到 [-1, 1] 范围
	var t=(index as float)/(total-1);  # 0 → 0, 最后一张 → 1
	t=t*2.0-1.0  # 第一张 → -1，最后一张 → 1
	# 最大倾斜角度（弧度）
	const MAX_ANGLE_DEG=15.0;
	var angle_rad=deg_to_rad(MAX_ANGLE_DEG);
	return t*angle_rad;
func _on_mouse_entered ():
	is_hovering=1;
	_move_cards(HOVER_UP_OFFSET);
func _on_mouse_exited ():
	is_hovering=0;
	_move_cards(0.0);
func _move_cards(y: float):
	current_y_offset=y;
	_apply_card_positions();
func _set_all_card_scale (scale_target: float):
	for i in hands:
		var tween=create_tween();
		tween.set_ease(Tween.EASE_OUT);
		tween.set_trans(Tween.TRANS_QUINT);
		tween.tween_property(i,"scale",Vector2(scale_target,scale_target),0.15)
func _on_card_hover_entered(card: BattleCardUI):
	#print("悬停: ", card.get_card_data().card_name);
	card.select_card(); #放大2倍，上浮
	_spread_cards(card);
func _on_card_hover_exited(card: BattleCardUI):
	card.deselect_card(); 
	_reset_card_positions()
func _spread_cards(hovered_card: BattleCardUI):
	if hovered_card == null:
		# 清除水平偏移
		current_x_offsets = []
		for i in range(hands.size()):
			current_x_offsets.append(0.0)
		_apply_card_positions()
		return
	
	var n = hands.size()
	if n <= 1:
		return
	
	var hovered_index = hands.find(hovered_card)
	current_x_offsets = []
	for i in range(n):
		if i == hovered_index:
			current_x_offsets.append(0.0)
			continue
		var distance = abs(i - hovered_index)
		var offset_sign = -1.0 if i < hovered_index else 1.0
		var scatter_offset = SCATTER_OFFSET_LEFT if i < hovered_index else SCATTER_OFFSET_RIGHT
		var offset_amount = scatter_offset / float(distance + 1)
		current_x_offsets.append(offset_sign * offset_amount)
	
	_apply_card_positions()
func _reset_card_positions():
	current_x_offsets = []
	for i in range(hands.size()):
		current_x_offsets.append(0.0)
	_apply_card_positions()
func _apply_card_positions():
	# 确保 current_x_offsets 长度与 hands 一致
	while current_x_offsets.size() < hands.size():
		current_x_offsets.append(0.0)
	while current_x_offsets.size() > hands.size():
		current_x_offsets.pop_back()
	
	for i in range(hands.size()):
		var card = hands[i]
		var base_pos = base_positions[i]
		var x_offset = current_x_offsets[i] if i < current_x_offsets.size() else 0.0
		var target_pos = Vector2(base_pos.x + x_offset, base_pos.y + current_y_offset)
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_property(card, "position", target_pos, 0.15)

func _on_hand_hover_entered():
	hover_count += 1
	if hover_count == 1:
		# 如果计时器正在运行，取消它（说明鼠标又回来了）
		exit_timer = 0.0
		is_hovering = true
		_move_cards(HOVER_UP_OFFSET)

func _on_hand_hover_exited():
	hover_count -= 1
	if hover_count == 0:
		# 启动延迟计时器，而不是立即下移
		exit_timer = EXIT_DELAY
		
func _process(delta):
	if exit_timer > 0:
		exit_timer -= delta
		if exit_timer <= 0:
			exit_timer = 0.0
			# 超时，确认鼠标已离开，执行下移
			is_hovering = false
			_move_cards(0.0)
