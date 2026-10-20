extends RefCounted;
class_name BattleSnapshotManager;

var current_turn_snapshot: Dictionary={}
var last_turn_snapshot: Dictionary={}

func save_snapshot(logic: BattleLogic, energy: EnergyPool, deck: Deck, enemies: Array):
	last_turn_snapshot=current_turn_snapshot.duplicate(1);
	var snap={};
	snap["logic"]=logic.get_snapshot();
	snap["energy"]=energy.get_snapshot();
	snap["deck"]=deck.get_snapshot();
	var enemies_data={};
	for i in range(enemies.size()):
		enemies_data[i]=enemies[i].get_snapshot();
	snap["enemies"]=enemies_data;
	current_turn_snapshot=snap;

func execute_time_action(mode: int, target_type: String, target_id: String, logic: BattleLogic, enemies: Array, on_hp_changed: Callable, on_enemy_intent_refreshed: Callable):
	if mode==TimeService.Mode.BACKWARD:
		if last_turn_snapshot.is_empty():
			print("[TimeSystem] 第一回合没有上一回合，无法回溯！")
			return;
		if target_type=="hp" && target_id=="player":
			var past_hp=last_turn_snapshot["logic"]["player_hp"];
			logic.player_hp=past_hp;
			on_hp_changed.call(logic.player_hp, logic.player_max_hp);
			print("[TimeSystem] 回溯成功！血量恢复到: ",logic.player_hp);
			
	elif mode==TimeService.Mode.FORWARD:
		if target_type=="intent":
			for enemy in enemies:
				if enemy.data.id==target_id:
					enemy.generate_new_intents();
					print("[TimeSystem] 红移成功！已刷新敌人意图。");
					# 通知 UI 刷新
					on_enemy_intent_refreshed.call(enemy);
					break;
