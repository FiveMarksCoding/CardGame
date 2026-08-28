extends RefCounted;
class_name  CardEffectSystem;
static func execute_card_effect (card_data: CardData,target: Enemy,battle_manager: BattleManager):
	# 伤害
	if card_data.damage>0 && target:
		target.take_damage(card_data.damage);
		#print("%s 对 %s 造成 %d 点伤害" % [card_data.card_name, target.data.name, card_data.damage])
	# 格挡
	if card_data.block > 0:
		battle_manager.player_block+=card_data.block;
		battle_manager.player_block_changed.emit(battle_manager.player_block);
		#print("获得 %d 点格挡" % card_data.block)
