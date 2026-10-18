extends RefCounted;
class_name Deck;

var draw_pile: Array[CardData]=[];
var discard_pile: Array[CardData]=[];
var consumed_pile: Array[CardData]=[];
var sum_deck: Array[CardData]=[];

func setup (cards: Array[CardData]):
	sum_deck=cards.duplicate();
	draw_pile=cards.duplicate();
	draw_pile.shuffle();
	discard_pile.clear();
	consumed_pile.clear();
func draw_one () -> CardData:
	if draw_pile.is_empty():
		_reshuffle();
	if draw_pile.is_empty():
		return null;
	return draw_pile.pop_front();
func discard (card: CardData):
	discard_pile.append(card);
func consume (card: CardData):
	consumed_pile.append(card);
func _reshuffle ():
	if discard_pile.is_empty():
		return ;
	draw_pile=discard_pile.duplicate();
	discard_pile.clear();
	draw_pile.shuffle();
## snapshot
# 在 Deck.gd 末尾添加

func get_snapshot() -> Dictionary:
	var draw_ids=[];
	for c in draw_pile: draw_ids.append(c.id);
	var discard_ids=[];
	for c in discard_pile: discard_ids.append(c.id);
	var consumed_ids=[];
	for c in consumed_pile: consumed_ids.append(c.id);
	return {
		"draw_pile": draw_ids,
		"discard_pile": discard_ids,
		"consumed_pile": consumed_ids
	};

func load_snapshot (data: Dictionary):
	if data.has("draw_pile"):
		draw_pile.clear();
		for id in data["draw_pile"]:
			var card=CardLib.get_card(id);
			if card: draw_pile.append(card);
	if data.has("discard_pile"):
		discard_pile.clear()
		for id in data["discard_pile"]:
			var card=CardLib.get_card(id);
			if card: discard_pile.append(card);
	if data.has("consumed_pile"):
		consumed_pile.clear()
		for id in data["consumed_pile"]:
			var card=CardLib.get_card(id);
			if card: consumed_pile.append(card);
