class_name MapScreen
extends Control

var map_data: MapData;
var map_container: Control;

var is_dragging: bool=0;
var drag_start: Vector2=Vector2.ZERO;
var container_start: float=0.0;
const DRAG_THRESHOLD: float=5.0;
#TEST
var max_x: int=300;
var min_x: int=-300;

func _ready():
	map_container=Control.new();
	add_child(map_container);
	
	map_data = MapData.new();
	map_data.generate_test_map();
	
	draw_map();

func draw_map ():
	for id in map_container.get_children():
		if id is Button:
			id.queue_free();
	
	for id in map_data.nodes:
		var node: MapData.MapNode = map_data.nodes[id];
		# 这个 node 是属于 MapData 类下的一个 MapNode
		# nodes 是 MapData 下一个字典
		var btn = Button.new();
		btn.size = Vector2(40,40);
		btn.position = node.position-(btn.size/2);
		var color = StyleBoxFlat.new();
		match node.node_type:
			MapData.NodeType.BATTLE:
				color.bg_color=Color.GREEN;
			MapData.NodeType.ELITE:
				color.bg_color=Color.PURPLE;
			MapData.NodeType.BOSS:
				color.bg_color=Color.RED;
			_:
				color.bg_color=Color.GRAY;
		if node.completed:
			color.bg_color=color.bg_color*0.3;
			btn.disabled=1;
		elif node.unlocked:
			btn.disabled=0;
		else:
			color.bg_color=color.bg_color*0.6;
			btn.disabled=1;
		
		btn.add_theme_stylebox_override("normal",color);
		btn.text = node.id;
		btn.pressed.connect(_on_node_clicked.bind(id));
		map_container.add_child(btn);
		# 将 btn 添加到 MapScreen 下的一个子节点
func _on_node_clicked (node_id: String):
	print("Click node:",node_id);
	var node=map_data.get_node(node_id);
	if !node:
		return ;
	if !(node.unlocked && !node.completed):
		return ;
	node.completed=1;
	for next in node.edges:
		var next_node=map_data.get_node(next);
		if next_node:
			next_node.unlocked=1;
	draw_map();
func _input (event: InputEvent):
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging=1;
			drag_start=event.position;
			container_start=map_container.position.x;
			Input.set_default_cursor_shape(Input.CURSOR_DRAG);
		else:
			is_dragging=0;
			Input.set_default_cursor_shape(Input.CURSOR_ARROW);
	elif event is InputEventMouseMotion:
		if is_dragging:
			if !(Input.get_mouse_button_mask() & MOUSE_BUTTON_LEFT):
				is_dragging=0;
				Input.set_default_cursor_shape(Input.CURSOR_ARROW);
				return ;
			var delta=event.position.x-drag_start.x;
			var now_x=container_start+delta;
			map_container.position.x=clamp(now_x,min_x,max_x);
