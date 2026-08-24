extends Control;
class_name HandContainer;
# 布局参数
const ARC_HEIGHT: float=10.0;       # 弧高，中间牌最高
const MAX_CARD_SPACING: float=-40;  # 负值 = 重叠
const ROT_MAX: float=0.17;           # 最大旋转弧度 (约 11.5°)
const CARD_WIDTH: float=120.0
const CARD_HEIGHT: float=160.0;
const CARD_SPACING: float=10.0;
const HOVER_UP_OFFSET: float=-60.0;  # 上移距离（负值表示向上）
const CARD_y: int=30;
const SCATTER_OFFSET_LEFT=60.0;      # 左撤退距离
const SCATTER_OFFSET_RIGHT=90.0;     # 右撤退距离
const MAX_ANGLE_DEG=15.0;   	# 最大倾斜角度（弧度）
const EXIT_DELAY: float=0.5  # 延迟时间（秒）
const HAND_MOVE_TIME=0.4  #打出牌后手牌排列速度

var hands: Array[BattleCardUI]=[];
var base_positions: Array[Vector2]=[];  # 存储每张牌的基准位置
var hover_count: int=0
var exit_timer: float=0.0  # 延迟计时器 计时防抖
var is_hovering: bool=0;  # 是否在手牌区域内
var current_y_offset: float=0.0;
var current_x_offsets: Array[float]=[];  # 每张牌独立的水平偏移
var t_pos: Array[Vector2]=[];  # 存储计算好的目标位置
var t_rot: Array[float]=[];      # 方向

func _ready ():
	mouse_filter=Control.MOUSE_FILTER_IGNORE;
	#HandContainer 不应该拦截鼠标事件
	hover_count = 0;
	current_x_offsets=[];
	for i in range(hands.size()):
		current_x_offsets.append(0.0);
	_add_test_cards();
func _get_battle_manager() -> BattleManager:
	var p=get_parent();
	while p:
		if p.has_node("BattleManager"):
			return p.get_node("BattleManager") as BattleManager;
		p=p.get_parent();
	return null;
func _add_test_cards():
	# 延迟 0.2 秒后开始抽牌，让玩家看到起始状态
	await get_tree().create_timer(0.2).timeout
	for i in range(5):
		_draw_one_card()
		await get_tree().create_timer(0.1).timeout  # 每张牌间隔 0.15 秒
#排列卡牌（只计算）
func _arrange_cards ():
	var n=hands.size();
	if n==0:
		base_positions.clear();
		t_pos.clear();
		t_rot.clear();
		return;
	base_positions.clear();
	t_pos.clear();
	t_rot.clear();
	var total_width=n*CARD_WIDTH+(n-1)*MAX_CARD_SPACING;
	var start_x=(size.x-total_width)/2.0;
	var y_offset=CARD_y;
	for i in range(n):
		var card=hands[i];
		# 离散化
		var t: float;
		if n==1:
			t=0.0;
		else:
			t=(float(i)/float(n-1))*2.0-1.0;       
		var x=start_x+i*(CARD_WIDTH+MAX_CARD_SPACING);
		var arc_offset=-ARC_HEIGHT*(t*t)+ARC_HEIGHT;
		var y=y_offset-arc_offset;  # arc_offset 为正，所以向上偏移
		# 旋转角度
		var rot=t*ROT_MAX;
		base_positions.append(Vector2(x,y));
		t_pos.append(Vector2(x, y));
		t_rot.append(rot);
	_apply_card_positions();
func _apply_card_pos():
	_apply_card_positions(true);
func _calculate_rotation(index: int, total: int) -> float:
	if total <= 1:
		return 0.0
	# 离散化
	var t=(index as float)/(total-1);  
	t=t*2.0-1.0;
	var angle_rad=deg_to_rad(MAX_ANGLE_DEG);
	return t*angle_rad;
# 统一移动卡牌，拒绝硬编码移动
func _move_cards(y: float):
	current_y_offset=y;
	_apply_card_positions();
func _set_all_card_scale (scale_target: float):
	for i in hands:
		var tween=create_tween();
		tween.set_ease(Tween.EASE_OUT);
		tween.set_trans(Tween.TRANS_QUINT);
		tween.tween_property(i,"scale",Vector2(scale_target,scale_target),0.15);
# 单卡选中
func _on_card_hover_entered(card: BattleCardUI):
	print("悬停触发")   # ← 加这行
	card.select_card(); 
	_spread_cards(card);
func _on_card_hover_exited(card: BattleCardUI):
	card.deselect_card(); 
	_reset_card_positions();
# 水平移开卡牌 区别_arrange_cards()
func _spread_cards(hovered_card: BattleCardUI):
	if hovered_card == null:
		# 清除水平偏移
		current_x_offsets=[];
		for i in range(hands.size()):
			current_x_offsets.append(0.0);
		_apply_card_positions();
		return ;
	var n = hands.size()
	if n <= 1:
		return
	var hovered_index=hands.find(hovered_card);
	current_x_offsets=[];
	for i in range(n):
		if i == hovered_index:
			current_x_offsets.append(0.0);
			continue;
		var distance=abs(i-hovered_index);
		var offset_sign=-1.0 if i<hovered_index else 1.0;
		var scatter_offset=SCATTER_OFFSET_LEFT if i<hovered_index else SCATTER_OFFSET_RIGHT;
		var offset_amount=scatter_offset/float(distance+1);
		current_x_offsets.append(offset_sign*offset_amount);
	_apply_card_positions();
func _reset_card_positions():
	current_x_offsets=[];
	for i in range(hands.size()):
		current_x_offsets.append(0.0);
	_apply_card_positions();
func _apply_card_positions(animate: bool = true):
	# 确保偏移数组长度匹配
	while current_x_offsets.size() < hands.size():
		current_x_offsets.append(0.0)
	while current_x_offsets.size() > hands.size():
		current_x_offsets.pop_back()
	
	for i in range(hands.size()):
		var card = hands[i]
		var base_pos = base_positions[i]
		var x_offset = current_x_offsets[i] if i < current_x_offsets.size() else 0.0
		var target_pos = Vector2(base_pos.x + x_offset, base_pos.y + current_y_offset)
		var target_rot = t_rot[i] if i < t_rot.size() else 0.0

		if animate:
			# 创建并执行一个 Tween 动画
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUINT)
			tween.tween_property(card, "position", target_pos, 0.2)
			tween.parallel().tween_property(card, "rotation", target_rot, 0.2)
		else:
			card.position = target_pos
			card.rotation = target_rot
func _on_hand_hover_entered():
	hover_count+=1;
	if hover_count==1:
		# 如果计时器正在运行，取消它（说明鼠标又回来了）
		exit_timer=0.0
		is_hovering=1;
		_move_cards(HOVER_UP_OFFSET);
func _on_hand_hover_exited():
	hover_count-=1;
	if hover_count==0:
		# 启动延迟计时器，而不是立即下移
		exit_timer=EXIT_DELAY;
func _process(delta):
	if exit_timer>0:
		exit_timer-=delta;
		if exit_timer<=0:
			exit_timer=0.0;
			# 超时，确认鼠标已离开，执行下移
			is_hovering=0;
			_move_cards(0.0);
# 打牌
# HandContainer.gd - 修改 play_card
func play_card (card: BattleCardUI,target: Vector2):
	card.set_interactive(false)
	card.select_card();
	var index=hands.find(card)
	if index!=-1:
		hands.remove_at(index);
		#base_positions.remove_at(index);
	_arrange_cards();
	_apply_card_pos();
	card.fly_to(target, 0.4, func():
		_card_hold_awit(card);
	)
	
# 打出后悬停，之后接别的
func _card_hold_awit (card: BattleCardUI):
	var tween=create_tween();
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		# 向右下角快速移动并消失
		var end_pos=Vector2(1280+100,720+100);
		var fly_tween=create_tween();
		fly_tween.set_ease(Tween.EASE_IN);
		fly_tween.set_trans(Tween.TRANS_QUINT);
		fly_tween.tween_property(card,"global_position",end_pos,0.15);
		fly_tween.tween_callback(card.queue_free);
	);
# 抽一张牌
func _draw_one_card ():
	var bm=_get_battle_manager();
	if bm==null:
		print("wrong\n");
		return ;
	var card_data=bm.draw_one();
	if card_data==null:
		return ;
	var card=BattleCardUI.new();
	card.setup(card_data); 
	card.hover_entered.connect(_on_card_hover_entered);
	card.hover_exited.connect(_on_card_hover_exited);
	card.hand_hover_entered.connect(_on_hand_hover_entered);
	card.hand_hover_exited.connect(_on_hand_hover_exited);
	add_child(card);
	hands.append(card);
	var s_pos=Vector2(-100,720-50);
	card.global_position=s_pos;
	_arrange_cards();
	_apply_card_positions();
# 弃一张牌
func discard_card(card: BattleCardUI):
	var index=hands.find(card);
	if index==-1: 
		return ;
	hands.remove_at(index);
	base_positions.remove_at(index);
	# 把卡牌从 HandContainer 移出（但还没销毁）
	remove_child(card);
	get_tree().root.add_child(card);
	card.global_position = global_position;
	# 重新排列剩余手牌
	_arrange_cards();
	# 让卡牌播放“弃牌动画”，动画结束后自动销毁
	card.play_discard_animation();

# HandContainer.gd - 实现 try_play_card
func try_play_card(card: BattleCardUI, mouse_pos: Vector2) -> void:
	# 先判断鼠标是否在有效目标区域内
	# 暂时统一用一个固定位置
	var target = Vector2(640,150)  # 屏幕中央偏上
	play_card(card, target)
