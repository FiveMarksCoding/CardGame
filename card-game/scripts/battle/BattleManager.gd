extends Node
class_name BattleManager
# 牌堆：抽牌堆、弃牌堆、消耗堆
var draw: Array[CardData]=[];
var discard: Array[CardData]=[]
var consumed: Array[CardData]=[];
var hand: Array[CardData]=[];


func _ready ():
	print("BattleManager 已加载");
	var copydeck=GameState.player_deck.duplicate();
	draw=copydeck;
	print("抽牌堆初始化完成，共 %d 张牌" % draw.size());
	print("战斗场景加载完成，等待手牌显示")
func shuffle_pile(pile: Array[CardData]) -> void:
	pile.shuffle();
func draw_one () -> CardData:
	if draw.is_empty():
		if discard.is_empty():
			return null;
		draw=discard;
		discard.clear();
		shuffle_pile(draw);
	return draw.pop_front();
