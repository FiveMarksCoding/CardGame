extends Node

var player_deck: Array=[];      # 玩家当前牌组
var gold: int=0;                # 金币
var relics: Array=[];           # 遗物（后续）
var current_layer: int=1;       # 当前大层

func _ready():
	print("GameState 已加载");
func create_new_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	deck.append(CardData.new("strike", "打击", 1, "attack", 5, 0, true, "", "blue", [ ["blue", "neutral"]]))
	deck.append(CardData.new("defend", "防御", 1, "skill", 0, 4, false, "", "neutral", [["neutral"]]))
	deck.append(CardData.new("strike", "打击", 1, "attack", 5, 0, true, "", "neutral", [["neutral"]]))
	deck.append(CardData.new("strike", "铁斩波", 1, "attack", 6, 6, true, "", "neutral", [["neutral"], ["neutral"]]))
	deck.append(CardData.new("defend", "防御", 1, "skill", 0, 4, false, "", "neutral", [["neutral"]]))
	deck.append(CardData.new("strike", "打击", 1, "attack", 5, 0, true, "", "blue", [["blue", "neutral"]]))
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
