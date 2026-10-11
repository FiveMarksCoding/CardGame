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
