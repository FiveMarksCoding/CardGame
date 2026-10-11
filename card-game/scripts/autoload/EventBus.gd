extends Node;

# 战斗意图
signal intent_play_card(card_uid: int,target_id: String);
signal intent_end_turn();
signal intent_color_card(card_uid: int);
# 战斗状态
signal battle_started();
signal battle_ended(vic: bool);
signal player_hp_changed(hp: int,max_hp: int);
signal player_block_changed(block: int);
signal energy_changed(queue: Array);
signal hand_changed();
signal enemy_state_changed(enemy_id: String);

# 地图
signal map_node_clicked(node_id: String);
signal map_completed();

# 奖励
signal reward_offered();
signal reward_claimed();
signal reward_dismissed();

# 局流程
signal run_started();
signal run_ended(vic: bool);
