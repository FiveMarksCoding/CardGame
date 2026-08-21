class_name MapData;
extends RefCounted;#用完就卸载，挂这个

enum NodeType {BATTLE,ELITE,BOSS,SHOP,CAMPFIRE,EVENT,};
#elite 精英
var nodes: Dictionary = {}
class MapNode:
	var id: String;
	var node_type: NodeType;
	var position: Vector2;
	var edges: Array[String] = [];
	var unlocked: bool = 0;
	var completed: bool = 0;
	
	func _init(p_id: String, p_type: NodeType, p_pos: Vector2):
		id = p_id;node_type = p_type;position = p_pos;

func generate_test_map():
	nodes.clear()
	
	# 第1层：起点
	var start = MapNode.new("start", NodeType.BATTLE, Vector2(200,400));
	start.unlocked = 1;
	start.completed = 1;
	nodes["start"] = start;
	#t2
	var node2 = MapNode.new("node2",NodeType.BATTLE,Vector2(400,400));
	node2.unlocked=1;
	nodes["node2"] = node2;
	nodes["start"].edges.append("node2");
	#t3
	var node3 = MapNode.new("node3",NodeType.BATTLE,Vector2(600,400));
	nodes["node3"] = node3;
	nodes["node2"].edges.append("node3");
	#t4
	var node4 = MapNode.new("node4",NodeType.BOSS,Vector2(800,400));
	nodes["node4"] = node4;
	nodes["node3"].edges.append("node4");
	
func get_node (id: String) -> MapNode:
	return nodes.get(id, null);
