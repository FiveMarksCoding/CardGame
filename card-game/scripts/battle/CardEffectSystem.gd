extends RefCounted;
class_name  CardEffectSystem;
static func execute_card_effect (card_data: CardData,target: Enemy,BS: BattleSystem):
	# 伤害
	if card_data.damage>0 && target:
		target.take_damage(card_data.damage);
	# 格挡
	if card_data.block > 0:
		BS.logic.player_block+=card_data.block;
		BS.logic.player_block_changed.emit(BS.logic.player_block);
