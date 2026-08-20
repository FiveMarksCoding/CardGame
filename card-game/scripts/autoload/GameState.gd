extends Node;

var player_deck: Array[CardData] = [];
var gold: int = 0;

func _ready():
	player_deck = create_new_deck();
	gold = 99;
	print("GameState 已加载, 卡组共 %d 张，gold = %d" % [player_deck.size(),gold]);
	
func create_new_deck() -> Array[CardData]:
	var deck:Array[CardData] = []
	deck.append(CardData.new("strike", "打击", 1, "attack", 5, 0, true));
	deck.append(CardData.new("strike", "打击", 1, "attack", 5, 0, true));
	deck.append(CardData.new("defend", "防御", 1, "skill", 0, 4, false));
	deck.append(CardData.new("defend", "防御", 1, "skill", 0, 4, false));
	return deck;
