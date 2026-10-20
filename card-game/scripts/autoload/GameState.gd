extends Node

var player_deck: Array[CardData]=[];
var gold: int=0;
var relics: Array=[];
var current_layer: int=1;
var time_charges: int=0;

func _ready():
	randomize();
	player_deck=create_new_deck();
	gold=99;
	time_charges=99;
	print("GameState 已加载，卡组共 %d 张" % player_deck.size());
func create_new_deck() -> Array:
	# 初始牌组：只写 ID，属性从 CardLib 读
	var starter_ids=[
		"strike_n",
		"strike_n",
		"strike_n",
		"defend",
		"defend",
		"iron_wave",
	];
	var deck: Array[CardData]=[];
	for id in starter_ids:
		var card=CardLib.get_card(id);
		if card==null:
			print("GameState：未找到卡牌 ", id);
			continue
		deck.append(card);
	return deck;
