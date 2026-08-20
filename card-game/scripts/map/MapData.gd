class_name MapData;
extends RefCounted;#用完就卸载，挂这个

enum NodeType {
	BATTLE,
	ELITE,#精英
	BOSS,
	SHOP,
	CAMPFIRE,
	EVENT,
	#
};

class MapNode:
	var id: String;
	var node_type: NodeType;
	var position: Vector2;
	var connection: Array[String] = [];
	var unlocked: bool = 0;
	var completed: bool = 0;
	
	func _init(p_id: String, p_type: NodeType, p_pos: Vector2):
		id = p_id;node_type = p_type;position = p_pos;
