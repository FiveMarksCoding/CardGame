extends Node
class_name BattleManager
# 牌堆：抽牌堆、弃牌堆、消耗堆
var is_player_turn: bool=0;
var turn_counts: int=0;
var draw: Array[CardData]=[];
var discard: Array[CardData]=[]
var consumed: Array[CardData]=[];
var hand: Array[CardData]=[];
var enemies: Array=[];
var player_health: int=100;
var player_max_health: int=100;
var player_block: int=0;
var hand_container: HandContainer=null;

var draw_count: int=5;
var hand_limit: int=10;
var _end_turn_btn:Button=null;

# Energy
var energy_q: Array = []  # 每个元素是 String，表示颜色类型
# 能量颜色常量（方便复用）
const ENERGY_NEUTRAL="neutral";
const ENERGY_RED = "red"
const ENERGY_BLUE = "blue"
const ENERGY_GREEN = "green"
const ENERGY_PURPLE = "purple"
const ENERGY_YELLOW = "yellow"
signal energy_changed();

func _ready ():
	print("BattleManager 已加载");
	hand_container=get_parent().get_node("HandContainer");
	if !hand_container:
		push_error("找不到 HandContainer！")
	create_end_btn();
	var copydeck=GameState.player_deck.duplicate();
	draw=copydeck;
	print("抽牌堆初始化完成，共 %d 张牌" % draw.size());
	#print("战斗场景加载完成，等待手牌显示")
	_create_player_ui();
	_update_player_ui(); # 刷新显示数值
	
	_create_test_enemies();
	start_player_turn();
func create_end_btn ():
	var btn=Button.new()
	btn.text="结束回合";
	btn.size=Vector2(140, 40);
	btn.pressed.connect(_on_end_btn_pressed);
	# 找 HandContainer 作为父节点
	@warning_ignore("shadowed_variable")
	var hand_container=get_parent().get_node("HandContainer");
	if hand_container:
		# 位置相对于 HandContainer：右下角
		btn.position=Vector2(hand_container.size.x-300,hand_container.size.y-200);
		hand_container.add_child(btn)
	else:
		# 如果找不到 HandContainer，直接加到根节点下（可能位置偏移）
		var parent=get_parent()
		btn.position=Vector2(1100, 620);
		parent.add_child(btn);
		btn.z_index=100;
	_end_turn_btn=btn;
func _on_end_btn_pressed ():
	if _end_turn_btn:
		_end_turn_btn.disabled=1;
	end_player_turn();
func shuffle_pile(pile: Array[CardData]) -> void:
	pile.shuffle();
func draw_hands (n: int=draw_count):
	await get_tree().create_timer(0.2).timeout;
	if !hand_container:
		return;
	for i in range(n):
		if draw.is_empty() && discard.is_empty():
			break;
		if i>0:
			await get_tree().create_timer(0.1).timeout
		if hand_container.hands.size()==hand_limit:
			var extra=draw_one();
			if extra:
				discard.append(extra);
				print("手牌已满，%s 被直接弃掉" % extra.card_name);
			else:
				break;
			continue;
		var s=hand_container.draw_one_card();
		if !s:
			break;
func discard_all ():
	if !hand_container:
		return ;
	while(hand_container.hands.size()>0):
		var card_ui=hand_container.hands[0];
		hand_container.discard_card(card_ui);
func draw_one () -> CardData:
	if draw.is_empty():
		if discard.is_empty():
			return null;
		draw=discard.duplicate();
		discard.clear();
		shuffle_pile(draw);
		print("弃牌堆已洗入抽牌堆，当前抽牌堆 %d 张" % draw.size())  # 新增调试信息
	return draw.pop_front();
func _create_test_enemies ():
	#type value times
	var intent_pool=[
		[
			Intent.new(Intent.Type.ATTACK,6,1),
			Intent.new(Intent.Type.DEFEND,4,1),
		],
		[
			Intent.new(Intent.Type.ATTACK,8,2),
		],
		[
			Intent.new(Intent.Type.BUFF,2,1),
			Intent.new(Intent.Type.ATTACK,6,1),
		],
	];
	var enemy_data=EnemyData.new("goblin_1","哥布林",30,intent_pool);
	var enemy=Enemy.new();
	enemy.setup(enemy_data);
	enemy.position=Vector2(400,300);
	enemy.scale=Vector2(1.5, 1.5);
	get_parent().add_child.call_deferred(enemy);
	enemies.append(enemy);
	print("Enemy created");
func start_player_turn():
	turn_counts+=1;
	print("=== 第 %d 回合开始 ==="%turn_counts)
	add_neutral_energy(3);
	# 抽牌（由 HandContainer 触发）
	await draw_hands();
	_update_player_ui();
	if _end_turn_btn:
		_end_turn_btn.disabled=0;
	is_player_turn=1;
func get_energy_queue() -> Array:
	return energy_q.duplicate();
func add_neutral_energy (n: int):
	for i in range(n):
		energy_q.append(ENERGY_NEUTRAL);
	energy_changed.emit();
func end_player_turn():
	if !is_player_turn:
		return ;
	is_player_turn=0;
	print("=== 玩家回合结束 ===");
	# 执行敌人回合
	discard_all();
	await execute_enemy_turn();
	# 敌人回合结束后，开始新的玩家回合
	start_player_turn()
	
func execute_enemy_turn():
	print("=== 敌人回合 ===")
	for enemy in enemies:
		if enemy.is_dead():
			continue
		
		print("%s 开始行动" % enemy.data.name)
		var results = enemy.execute_intents()
		
		for result in results:
			if result.has("damage"):
				var actual_damage = reduce_damage_with_block(result["damage"])
				if actual_damage > 0:
					take_player_damage(actual_damage)
					print("玩家受到 %d 点伤害" % actual_damage)
				else:
					print("格挡完全挡住了攻击！")
			
			if result.has("block"):
				print("%s 获得 %d 点格挡（暂未实现）" % [enemy.data.name, result["block"]])
			
			if result.has("strength"):
				print("%s 获得 %d 点力量（暂未实现）" % [enemy.data.name, result["strength"]])
			
			if result.has("heal"):
				pass  # 已在 Enemy 内部处理
		
		if is_player_dead():
			print("玩家死亡！游戏结束")
			return
		
		await get_tree().create_timer(0.5).timeout
	
	print("=== 敌人回合结束 ===")
	return
func reduce_damage_with_block (damage: int) -> int:
	if player_block>=damage:
		player_block-=damage;
		return 0;
	var remaining=damage-player_block;
	player_block=0;
	return remaining;
func take_player_damage (amount: int):
	player_health-=amount;
	if player_health<0:
		player_health=0;
		_update_player_ui();
	print("玩家生命: %d/%d" % [player_health,player_max_health]);
func is_player_dead () -> bool:
	return player_health<=0;
# BattleManager.gd - 新增函数

var _player_ui_layer: CanvasLayer = null
var _hp_label: Label = null
var _block_label: Label = null

func _create_player_ui():
	# 1. 创建独立 UI 层
	_player_ui_layer = CanvasLayer.new()
	add_child(_player_ui_layer)
	
	# 2. 背景面板（稍微半透明，看着舒服）
	var panel = Panel.new()
	panel.size = Vector2(180, 70)
	panel.position = Vector2(20, 650)  # 左下角
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_player_ui_layer.add_child(panel)
	
	# 3. 生命值文本
	_hp_label = Label.new()
	_hp_label.position = Vector2(15, 15)
	_hp_label.size = Vector2(150, 30)
	_hp_label.add_theme_font_size_override("font_size", 22)
	_hp_label.add_theme_color_override("font_color", Color.RED)
	_hp_label.text = "❤ 100/100"
	panel.add_child(_hp_label)
	
	# 4. 格挡值文本
	_block_label = Label.new()
	_block_label.position = Vector2(15, 45)
	_block_label.size = Vector2(150, 20)
	_block_label.add_theme_font_size_override("font_size", 16)
	_block_label.add_theme_color_override("font_color", Color.CYAN)
	_block_label.text = "🛡 0"
	panel.add_child(_block_label)

func _update_player_ui():
	if _hp_label:
		_hp_label.text = "❤ %d/%d" % [player_health, player_max_health]
	if _block_label:
		_block_label.text = "🛡 %d" % player_block
func consume_energy(requirements: Array) -> bool:
	var temp_q=energy_q.duplicate();
	var used_indexes: Array=[];
	for i in requirements:
		var yes=0;
		for j in range(temp_q.size()):
			# 如果该索引已被使用，跳过
			if j in used_indexes:
				continue;
			# 检查当前能量颜色是否满足需求
			if temp_q[j] in i:
				used_indexes.append(j);
				yes=1;
				break;
		if !yes:
			return 0;
	used_indexes.sort();
	for i in range(used_indexes.size()-1,-1,-1):
		energy_q.remove_at(used_indexes[i]);
	energy_changed.emit();
	return 1;
