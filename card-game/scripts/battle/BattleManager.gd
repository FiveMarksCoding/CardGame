extends Node
class_name BattleManager
# 牌堆：抽牌堆、弃牌堆、消耗堆
var draw: Array[CardData]=[];
var discard: Array[CardData]=[]
var consumed: Array[CardData]=[];
var hand: Array[CardData]=[];
# 基本信息
var is_player_turn: bool=0;
var turn_counts: int=0;
var enemies: Array=[];
var player_health: int=100;
var player_max_health: int=100;
var player_block: int=0;
var hand_container: HandContainer=null;
var draw_count: int=5;
var hand_limit: int=10;
var battle_over: bool=0; # 赢了还是死了？不知道
# Energy
var energy_q: Array=[];  # 每个元素是 String，表示颜色类型
# 能量颜色常量（方便复用）
const ENERGY_NEUTRAL="neutral";
const ENERGY_RED="red";
const ENERGY_BLUE="blue";
const ENERGY_GREEN="green";
const ENERGY_PURPLE="purple";
const ENERGY_YELLOW="yellow";
# 信号
signal energy_changed();
signal player_health_changed(new_health: int,max_health: int);
signal player_block_changed(new_block: int);
signal turn_started(turn_count: int);

func _ready ():
	#test_map_data();
	print("BattleManager 已加载");
	hand_container=get_parent().get_node("HandContainer");
	if !hand_container:
		push_error("找不到 HandContainer！");
	var copydeck=GameState.player_deck.duplicate();
	draw=copydeck;
	print("抽牌堆初始化完成，共 %d 张牌" % draw.size());
	#print("战斗场景加载完成，等待手牌显示")
	
	_create_test_enemies();
	start_player_turn();
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
			Intent.new(Intent.Type.ATTACK,5,1),
			Intent.new(Intent.Type.DEFEND,4,1),
		],
		[
			Intent.new(Intent.Type.ATTACK,6,2),
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
	enemy.scale=Vector2(1.5,1.5);
	get_parent().add_child.call_deferred(enemy);
	#enemy.setup(enemy_data);
	enemy.died.connect(_on_enemy_died);
	enemies.append(enemy);
	print("Enemy created");
func start_player_turn():
	for enemy in enemies:
		enemy.generate_new_intents();
	turn_counts+=1;
	add_neutral_energy(3);
	# 抽牌（由 HandContainer 触发）
	await draw_hands();
	turn_started.emit(turn_counts);
	is_player_turn=1;
func get_energy_queue() -> Array:
	return energy_q.duplicate();
func add_neutral_energy (n: int):
	for i in range(n):
		energy_q.append(ENERGY_NEUTRAL);
	energy_changed.emit();
func end_player_turn():
	if !is_player_turn || battle_over:
		return ;
	is_player_turn=0;
	print("=== 玩家回合结束 ===");
	# 执行敌人回合
	await execute_enemy_turn();
	discard_all();
	# 敌人回合结束后，开始新的玩家回合
	start_player_turn()
	
func execute_enemy_turn():
	print("=== 敌人回合 ===")
	for enemy in enemies:
		if enemy.is_dead():
			continue
		
		print("%s 开始行动" % enemy.data.name)
		var results = enemy.execute_intents()
		_check_victory()
		if battle_over:
			break;
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
		player_block_changed.emit(player_block);
		return 0;
	var remaining=damage-player_block;
	player_block=0;
	player_block_changed.emit(player_block);
	return remaining;
func take_player_damage (amount: int):
	player_health-=amount;
	if player_health<0:
		player_health=0;
	player_health_changed.emit(player_health,player_max_health);
	#print("玩家生命: %d/%d" % [player_health,player_max_health]);
func is_player_dead () -> bool:
	return player_health<=0;
func consume_energy(requirements: Array) -> bool:
	var temp_q=energy_q.duplicate();
	var used_indexes: Array=[];
	var n=temp_q.size();
	for i in requirements:
		var chosen=-1;   # index
		for j in range(n):
			if j in used_indexes:
				continue;
			var e_color=temp_q[j];
			if (e_color!=ENERGY_NEUTRAL) && (e_color in i):
				chosen=j;
				break;
		if (chosen==-1) && (ENERGY_NEUTRAL in i):
			for j in range(n):
				if j in used_indexes:
					continue;
				if temp_q[j]==ENERGY_NEUTRAL:
					chosen=j;
					break;
		if chosen==-1:
			return 0;
		used_indexes.append(chosen);
	used_indexes.sort();
	for i in range(used_indexes.size()-1,-1,-1):
		energy_q.remove_at(used_indexes[i]);
	energy_changed.emit();
	return 1;
# 尝试染色：将手牌颜色添加到能量队列
# 返回: 是否成功染色
func try_color_card(card_data: CardData) -> bool:
	if card_data.card_color==ENERGY_NEUTRAL:
		return 0;
	# 检查是否有无色能量（从左到右找第一个）
	var neutral_index=-1;
	for i in range(energy_q.size()):
		if energy_q[i]==ENERGY_NEUTRAL:
			neutral_index=i;
			break;
	if neutral_index==-1:
		return 0;
	energy_q[neutral_index]=card_data.card_color;
	energy_changed.emit();
	#print("染色成功：%s → %s" % [card_data.card_name, card_data.card_color])
	return 1;
# 检测胜利
func _check_victory () -> void:
	if battle_over:
		return;
	var all_dead=1;
	for enemy in enemies:
		if !enemy.is_dead():
			all_dead=0;
			break;
	if all_dead:
		battle_over=1;
		_on_victory()
func _on_victory ():
	print("战斗胜利！")
	# 调用奖励系统
	var rewards = RewardGenerator.generate("normal");  # 暂时固定为 normal
	var logic = BattleRewardLogic.new();
	logic.initialize(rewards);
	# 创建 UI 并显示
	var ui=BattleRewardUI.new();
	add_child(ui);
	ui.show_rewards(logic);
# 检查是否所有敌人都死亡
func _on_enemy_died(_enemy: Enemy):
	var all_dead = true
	for e in enemies:
		if not e.is_dead():
			all_dead = false
			break
	if all_dead:
		battle_over = true
		_on_victory()
