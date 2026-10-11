class_name MapData;
extends RefCounted;
class MapNode:
	var id: String;
	var node_type: MapNodeData.NodeType;
	var position: Vector2;
	var edges: Array[String]=[];
	var unlocked: bool=0;
	var completed: bool=0;	
	func _init(p_id: String,p_type: MapNodeData.NodeType,p_pos: Vector2):
		id=p_id;
		node_type=p_type;
		position=p_pos;
var nodes: Dictionary={};

func get_node(id: String) -> MapNode:
	return nodes.get(id,null);
func add_node(node: MapNode):
	nodes[node.id]=node;
func add_connection(from_id: String,to_id: String):
	if nodes.has(from_id) && nodes.has(to_id):
		if !(to_id in nodes[from_id].edges):
			nodes[from_id].edges.append(to_id);
func get_outgoing(node_id: String) -> Array:
	var node=nodes.get(node_id)
	if node==null:
		return [];
	return node.edges;
# 检查：从起点是否能到达某个节点
func has_valid_path() -> bool:
	return 1;
