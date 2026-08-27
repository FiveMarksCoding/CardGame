extends Control;
class_name HandContainer;
# 布局参数
const ARC_HEIGHT: float=10.0;       # 弧高，中间牌最高
const MAX_CARD_SPACING: float=-40;  # 负值 = 重叠
const ROT_MAX: float=0.17;           # 最大旋转弧度 (约 11.5°)
const CARD_WIDTH: float=120.0
const CARD_HEIGHT: float=160.0;
const CARD_SPACING: float=10.0;
const HOVER_UP_OFFSET: float=-30.0;  # 上移距离（负值表示向上）
const CARD_y: int=60;
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
var drag_active: bool=0;
var drag_card: BattleCardUI=null;

func _ready ():
	z_index=99;
	mouse_filter=Control.MOUSE_FILTER_IGNORE;
	#HandContainer 不应该拦截鼠标事件
	hover_count=0;
	current_x_offsets=[];
	for i in range(hands.size()):
		current_x_offsets.append(0.0);
	_create_energy_ui();
func _create_energy_ui ():
	var EnergyUI_script=preload("res://scripts/battle/EnergyUI.gd");
	var energy_ui=EnergyUI_script.new();
	energy_ui.name="EnergyUI";
	energy_ui.position=Vector2(0,size.y-250);
	energy_ui.size=Vector2(size.x,40);
	add_child(energy_ui);
func _get_battle_manager() -> BattleManager:
	var p=get_parent();
	while p:
		if p.has_node("BattleManager"):
			return p.get_node("BattleManager") as BattleManager;
		p=p.get_parent();
	return null;
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
	#print("悬停触发")   # ← 加这行
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
		if (card==drag_card && drag_active) || !animate:
			continue;
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
	if hover_count==1 && !drag_active:
		exit_timer=0.0;
		is_hovering=1;
		_move_cards(HOVER_UP_OFFSET);

func _on_hand_hover_exited():
	hover_count-=1
	if hover_count==0 && !drag_active:
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
func play_card (card: BattleCardUI,target: Vector2,enemy: Enemy=null):
	card.set_interactive(0);
	card.select_card();
	var index=hands.find(card)
	if index!=-1:
		hands.remove_at(index);
		var bm=_get_battle_manager();
		if bm:
			bm.discard.append(card.card_data);
			#print("打出并弃牌：", card.card_data.card_name);
		#base_positions.remove_at(index);
	_arrange_cards();
	_apply_card_pos();
	card.fly_to(target, 0.4, func():
		_execute_card_effect(card.card_data,enemy);
		_card_hold_awit(card);
	)
func _execute_card_effect (card_data: CardData,target: Enemy):
	var bm=_get_battle_manager();
	if bm==null:
		return ;
	# 伤害
	if card_data.damage > 0 && target:
		target.take_damage(card_data.damage)
		print("%s 对 %s 造成 %d 点伤害" % [card_data.card_name, target.data.name, card_data.damage])

	# 格挡
	if card_data.block > 0:
		bm.player_block += card_data.block
		bm._update_player_ui()
		print("获得 %d 点格挡" % card_data.block)
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
func draw_one_card () -> bool:
	var bm=_get_battle_manager();
	if bm==null:
		print("wrong\n");
		return 0;
	var card_data=bm.draw_one();
	if card_data==null:
		return 0;
	var card=BattleCardUI.new();
	card.setup(card_data); 
	card.hover_entered.connect(_on_card_hover_entered);
	card.hover_exited.connect(_on_card_hover_exited);
	card.hand_hover_entered.connect(_on_hand_hover_entered);
	card.hand_hover_exited.connect(_on_hand_hover_exited);
	card.drag_started.connect(_on_card_drag_started);
	card.drag_ended.connect(_on_card_drag_ended);
	card.drag_moved.connect(_on_card_drag_moved);
	add_child(card);
	hands.append(card);
	var s_pos=Vector2(-100,720-50);
	card.global_position=s_pos;
	_arrange_cards();
	_apply_card_positions();
	return 1;
# 弃一张牌
func discard_card(card: BattleCardUI):
	var index=hands.find(card);
	if index==-1: 
		return ;
	var global_pos=card.global_position;
	var bm=_get_battle_manager();
	if bm:
		var card_data=card.card_data;  
		bm.discard.append(card_data);  
		print("弃牌：",card_data.card_name);
		
	hands.remove_at(index);
	base_positions.remove_at(index);
	# 重新排列剩余手牌
	_arrange_cards();
	card.play_discard_animation();
# 手牌区域计算
func _get_hand_area () -> Rect2:
	#print(base_positions);
	if !base_positions.size():
		return Rect2();
	var min_x=base_positions[0].x;
	var max_x=base_positions[0].x+CARD_WIDTH;
	var min_y=base_positions[0].y;
	var max_y=base_positions[0].y+CARD_HEIGHT;
	for i in base_positions:
		min_x=min(min_x,i.x);
		max_x=max(max_x,i.x+CARD_WIDTH);
		min_y=min(min_y,i.y);
		max_y=max(max_y,i.y+CARD_HEIGHT);
	var t=20.0;  # margin
	return Rect2(min_x-t,min_y-t,max_x-min_x+t*2,max_y-min_y+t*2);
@warning_ignore("unused_parameter")
# HandContainer.gd - 替换 try_play_card

func try_play_card(card: BattleCardUI, mouse_pos: Vector2):
	var local_mouse=get_local_mouse_position()
	var hand_area=_get_hand_area()
	if hand_area.has_point(local_mouse):
		_cancel_play(card)
		return
	var bm=_get_battle_manager()
	if bm==null:
		return;
	# 目标检查
	var target: Enemy=null;
	if card.card_data.needs_target:
		target=_get_target_at_mouse(mouse_pos);
		if target==null:
			# 没有目标，取消打出
			_cancel_play(card);
			return;
	# 能量检查
	var reqs=card.card_data.energy_re;
	if !reqs.is_empty():
		if !bm.consume_energy(reqs):
			_cancel_play(card);
			return;
	# 执行打出
	var target_pos=Vector2(930,240);
	play_card(card,target_pos,target);
func _cancel_play(card: BattleCardUI):
	card.set_interactive(1);
	var index=hands.find(card);
	if index!=-1:
		@warning_ignore("shadowed_variable")
		var t_pos=base_positions[index];
		var tar_rot=t_rot[index];
		var tween=create_tween();
		tween.set_ease(Tween.EASE_OUT);
		tween.set_trans(Tween.TRANS_QUINT);
		tween.tween_property(card,"position",t_pos,0.2);
		tween.parallel().tween_property(card,"rotation",tar_rot,0.2);
	else:
		print("错误：手上有未知卡牌");
		card.queue_free();
# 拖拽控制手牌上浮
func _on_card_drag_started(card: BattleCardUI, mouse_pos: Vector2):
	drag_active=1;
	drag_card=card;
	if card.card_data.needs_target:
		card._create_aim_line();
	_update_drag_float(mouse_pos);
@warning_ignore("unused_parameter")
func _on_card_drag_moved(card: BattleCardUI, mouse_pos: Vector2):
	if drag_active:
		_update_drag_float(mouse_pos);
		if card.card_data.needs_target:
			var targ=_get_target_at_mouse(mouse_pos);
			var is_valid=(targ!=null);
			card._update_aim_line(is_valid);
			_highlight_target(targ);
@warning_ignore("unused_parameter")
func _on_card_drag_ended(card: BattleCardUI, mouse_pos: Vector2):
	drag_active=0;
	drag_card=null;
	card._clear_aim_line();
	_highlight_target(null);
	_update_float_from_hover();
@warning_ignore("unused_parameter")
func _update_drag_float (pos: Vector2):
	if drag_active && drag_card && drag_card.card_data.needs_target:
		return ;5
	var local_mouse=get_local_mouse_position();
	var hand_area=_get_hand_area();
	if hand_area.has_point(local_mouse):
		if current_y_offset!=HOVER_UP_OFFSET:
			_move_cards(HOVER_UP_OFFSET);
	else:
		if current_y_offset!=0.0:
			_move_cards(0.0);
# 获取鼠标下的敌人目标
func _get_target_at_mouse(mouse_pos: Vector2) -> Enemy:
	var bm=_get_battle_manager();
	if !bm:
		return null;
	var global_mouse=get_global_mouse_position()
	for enemy in bm.enemies:
		if enemy.is_dead():
			continue;
		# 距离检测：敌人中心点半径40像素（约等于碰撞体大小的一半）
		if global_mouse.distance_to(enemy.global_position)<40:
			return enemy;
	return null;
# 高亮/取消高亮目标
func _highlight_target(target: Enemy):
	# 先清除所有敌人高亮
	var bm=_get_battle_manager();
	if !bm:
		return;
	for enemy in bm.enemies:
		enemy.modulate=Color.WHITE
		if enemy==target:
			enemy.modulate=Color(1.5, 1.5, 0.5);  # 亮黄色高亮
func _update_float_from_hover ():
	if hover_count>0:
		_move_cards(HOVER_UP_OFFSET);
	else:
		_move_cards(0.0);
func request_color_card(card: BattleCardUI):
	var bm=_get_battle_manager()
	if bm==null:
		return ;
	if !bm.is_player_turn:
		#print("敌人回合，无法染色")
		return ;
	if !(card in hands):
		return ;
	# 尝试染色
	var s=bm.try_color_card(card.card_data)
	if s:
		discard_card(card);
	else:
		print("染色失败");
