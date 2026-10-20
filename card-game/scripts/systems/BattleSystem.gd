extends Node
class_name BattleSystem;
# 牌堆
var deck: Deck=Deck.new();
var hand: Array[CardData]=[];
# 战斗核心
var logic: BattleLogic=BattleLogic.new();
var enemies: Array=[];
var hand_container: HandContainer=null;
var draw_count: int=5;
var hand_limit: int=10;
# 能量
var energy_pool: EnergyPool=EnergyPool.new();
# 信号
signal energy_changed();
signal player_health_changed(new_health: int,max_health: int);
signal player_block_changed(new_block: int);
signal turn_started(turn_count: int);
# data
var battle_type: String="normal";
# 快照管理器
var snapshot_manager: BattleSnapshotManager=BattleSnapshotManager.new();

func _ready ():
	EventBus.time_action_executed.connect(_on_time_action_executed);
	
	if MapSystem.instance && (MapSystem.instance.current_node_id != ""):
		var node=MapSystem.instance.current_map_data.get_node(MapSystem.instance.current_node_id);
		if node:
			match node.node_type:
				MapNodeData.NodeType.ELITE:
					battle_type="elite";
				MapNodeData.NodeType.BOSS:
					battle_type="boss";
	print("当前战斗类型: ",battle_type);
	
	print("BattleSystem 已加载");
	hand_container=get_parent().get_node("HandContainer");
	if !hand_container:
		push_error("找不到 HandContainer！");
	deck.setup(GameState.player_deck);
	_create_test_enemies();
	start_player_turn();

func draw_hands (n: int=draw_count):
	await get_tree().create_timer(0.2).timeout;
	if !hand_container:
		return;
	for i in range(n):
		if deck.draw_pile.is_empty() && deck.discard_pile.is_empty():
			break;
		if i>0:
			await get_tree().create_timer(0.1).timeout;
		if hand_container.hands.size()==hand_limit:
			var extra=deck.draw_one();
			if extra:
				deck.discard(extra);
				print("手牌已满，%s 被直接弃掉" % extra.card_name);
			else:
				break;
			continue;
		var s=hand_container.draw_one_card();
		if !s:
			break;

func discard_all ():
	if !hand_container:
		return;
	while hand_container.hands.size()>0:
		var card_ui=hand_container.hands[0];
		hand_container.discard_card(card_ui);

func _create_test_enemies ():
	var hp = 1
	var atk = 5
	if battle_type == "elite":
		hp = 2
		atk = 8
	elif battle_type == "boss":
		hp = 3
		atk = 12
		
	var intent_pool=[
		[
			Intent.new(Intent.Type.ATTACK,atk,1),
			Intent.new(Intent.Type.DEFEND,4,1),
		],
		[
			Intent.new(Intent.Type.ATTACK,atk+2,2),
		],
		[
			Intent.new(Intent.Type.BUFF,2,1),
			Intent.new(Intent.Type.ATTACK,atk,1),
		],
	];
	var enemy_data=EnemyData.new("goblin_1","测试怪("+battle_type+")",hp,intent_pool);
	var enemy=Enemy.new();
	enemy.setup(enemy_data);
	enemy.position=Vector2(400,300);
	enemy.scale=Vector2(1.5,1.5);
	get_parent().add_child.call_deferred(enemy);
	enemy.died.connect(_on_enemy_died);
	enemies.append(enemy);
	print("Enemy created");

func start_player_turn ():
	for enemy in enemies:
		enemy.generate_new_intents();
	logic.start_player_turn();
	add_neutral_energy(3);
	await draw_hands();
	
	# 使用 Manager 存快照
	snapshot_manager.save_snapshot(logic,energy_pool,deck,enemies);
	
	TimeService.used_targets_this_turn.clear() # 重置本回合使用记录
	turn_started.emit(logic.turn_count);

func end_player_turn ():
	if !logic.is_player_turn || logic.battle_over:
		return;
	logic.end_player_turn();
	print("=== 玩家回合结束 ===");
	await execute_enemy_turn();
	discard_all();
	start_player_turn();

func execute_enemy_turn ():
	print("=== 敌人回合 ===");
	for enemy in enemies:
		if enemy.is_dead():
			continue;
		print("%s 开始行动" % enemy.data.name);
		var results=enemy.execute_intents();
		_check_victory();
		if logic.battle_over:
			break;
		for result in results:
			if result.has("damage"):
				var actual=take_player_damage(result["damage"]);
				if actual>0:
					print("玩家受到 %d 点伤害" % actual);
				else:
					print("格挡完全挡住了攻击！");
			if result.has("block"):
				print("%s 获得 %d 点格挡（暂未实现）" % [enemy.data.name,result["block"]]);
			if result.has("strength"):
				print("%s 获得 %d 点力量（暂未实现）" % [enemy.data.name,result["strength"]]);
			if result.has("heal"):
				pass;
		if logic.is_player_dead():
			print("玩家死亡！游戏结束");
			return;
		await get_tree().create_timer(0.5).timeout;
	print("=== 敌人回合结束 ===");
	return;

func reduce_damage_with_block (damage: int) -> int:
	var remaining=logic.reduce_with_block(damage);
	player_block_changed.emit(logic.player_block);
	return remaining;

func take_player_damage (amount: int) -> int:
	var actual=logic.take_damage(amount);
	player_health_changed.emit(logic.player_hp,logic.player_max_hp);
	return actual;

func is_player_dead () -> bool:
	return logic.is_player_dead();

# 能量
func get_energy_queue () -> Array:
	return energy_pool.get_queue();

func add_neutral_energy (n: int):
	energy_pool.add_neutral(n);
	energy_changed.emit();

func consume_energy (requirements: Array) -> bool:
	var ok=energy_pool.consume(requirements);
	if ok:
		energy_changed.emit();
	return ok;

func try_color_card (card_data: CardData) -> bool:
	var ok=energy_pool.color_card(card_data);
	if ok:
		energy_changed.emit();
	return ok;

# 胜负
func _check_victory () -> void:
	if logic.battle_over:
		return;
	var all_dead=1;
	for enemy in enemies:
		if !enemy.is_dead():
			all_dead=0;
			break;
	if all_dead:
		logic.mark_victory();
		_on_victory();

func _on_victory ():
	print("战斗胜利！");
	var rewards=RewardGenerator.generate(battle_type);
	var rlogic=RewardLogic.new();
	rlogic.initialize(rewards);
	var ui=RewardUI.new();
	add_child(ui);
	ui.reward_completed.connect(_on_reward_completed);
	ui.show_rewards(rlogic);

func _on_enemy_died (_enemy: Enemy):
	var all_dead=true;
	for e in enemies:
		if not e.is_dead():
			all_dead=false;
			break;
	if all_dead:
		logic.mark_vic();
		_on_victory();

func _on_reward_completed ():
	print("_on_reward_completed 被调用");
	EventBus.battle_ended.emit(1);
	_cleanup_battle();

func _cleanup_battle ():
	get_tree().create_timer(0.1).timeout.connect(func():
		get_parent().queue_free();
	);

func resolve_card (card_data: CardData, target: Enemy) -> void:
	var result=CardResolver.resolve(card_data,target,logic);
	if result["damage"]>0:
		print("%s 对 %s 造成 %d 点伤害" % [card_data.card_name,target.data.name,result["damage"]]);
	if result["block"]>0:
		player_block_changed.emit(logic.player_block);
		print("获得 %d 点格挡" % result["block"]);

# 时间操作转发
func _on_time_action_executed(mode: int, target_type: String, target_id: String):
	snapshot_manager.execute_time_action(
		mode,target_type,target_id,logic,enemies,
		func(hp,max_hp): player_health_changed.emit(hp,max_hp),
		func(enemy): pass
	);
