extends RefCounted;
class_name EnergyPool;

const ENERGY_NEUTRAL="neutral";
const ENERGY_RED="red";
const ENERGY_BLUE="blue";
const ENERGY_GREEN="green";
const ENERGY_PURPLE="purple";
const ENERGY_YELLOW="yellow";
var queue: Array=[];

func clear ():
	queue.clear();
func add_neutral (n: int):
	for i in range(n):
		queue.append(ENERGY_NEUTRAL);
func get_queue () -> Array:
	return queue.duplicate();
func consume (requirements: Array) -> bool:
	var temp_q=queue.duplicate();
	var used_indexes: Array=[];
	var n=temp_q.size();
	for i in requirements:
		var chosen=-1;
		for j in range(n):
			if j in used_indexes:
				continue;
			var e_color=temp_q[j];
			if (e_color!=ENERGY_NEUTRAL) && (e_color in i):
				chosen=j;
				break;
		if (chosen==-1) && (ENERGY_NEUTRAL in i):
			for j in range(n):
				if j in used_indexes:
					continue;
				if temp_q[j]==ENERGY_NEUTRAL:
					chosen=j;
					break;
		if chosen==-1:
			return 0;
		used_indexes.append(chosen);
	used_indexes.sort();
	for i in range(used_indexes.size()-1,-1,-1):
		queue.remove_at(used_indexes[i]);
	return 1;
func color_card (card_data: CardData) -> bool:
	if card_data.card_color==ENERGY_NEUTRAL:
		return 0;
	var neutral_index=-1;
	for i in range(queue.size()):
		if queue[i]==ENERGY_NEUTRAL:
			neutral_index=i;
			break;
	if neutral_index==-1:
		return 0;
	queue[neutral_index]=card_data.card_color;
	return 1;
## snapshot
func get_snapshot() -> Dictionary:
	return {
		"queue": queue.duplicate()
	};
func load_snapshot(data: Dictionary):
	if data.has("queue"):
		queue=data["queue"].duplicate();
