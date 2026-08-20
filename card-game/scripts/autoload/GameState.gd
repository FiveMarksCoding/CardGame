extends Node;
#class_name GameState; #autoload 自带了

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
func add_new_card (card: CardData) -> void:
	player_deck.append(card);
func remove_card (index :int) -> bool:
	if index >= 0 && index < player_deck.size():
		player_deck.remove_at(index);
		return 1;
	else:
		return 0;
func add_gold (amount: int) -> void:
	gold += amount;
func spend_gold (amount: int) -> void:
	gold -= amount;
	gold = max(gold,0);
func is_spend (amount: int) -> bool: #is_spending_legal
	if amount <= gold:
		return 1;
	else:
		return 0;
