# MapScreen.gd
class_name MapScreen
extends Control

var map_data: MapData = null
var map_container: Control
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var container_start: float = 0.0
const DRAG_THRESHOLD: float = 5.0

func _ready():
	print("[MapScreen] _ready 开始");
	map_container=Control.new();
	add_child(map_container);
	print("[MapScreen] MapSystem.instance = ", MapSystem.instance);
	_load_current_map();
	
	# 调试按钮
	var debug_btn=Button.new();
	debug_btn.text="下一层 (调试)";
	debug_btn.position=Vector2(10,10);
	debug_btn.pressed.connect(_on_debug_next_layer);
	add_child(debug_btn);
	print("[MapScreen] _ready 结束");

func _on_debug_next_layer():
	if MapSystem.instance==null:
		return;
	MapSystem.instance.go_to_next_layer();
	_load_current_map();

func _load_current_map():
	if MapSystem.instance==null:
		print("[MapScreen] MapSystem 未初始化");
		return;
	map_data = MapSystem.instance.generate_current_map();
	print("[MapScreen] map_data = ", map_data);
	if map_data:
		print("[MapScreen] nodes.size() = ", map_data.nodes.size());
	draw_map();

func draw_map():
	for child in map_container.get_children():
		child.queue_free();
	
	if map_data==null:
		print("[MapScreen] draw_map: map_data 为空");
		return;
	
	# 绘制连接线
	for id in map_data.nodes:
		var node=map_data.nodes[id];
		for next_id in node.edges:
			var next_node=map_data.nodes[next_id];
			if next_node==null:
				continue;
			var line=Line2D.new();
			line.add_point(node.position);
			line.add_point(next_node.position);
			line.width=2.0;
			line.default_color=Color.GRAY;
			map_container.add_child(line);
	
	# 绘制节点按钮
	for id in map_data.nodes:
		var node=map_data.nodes[id];
		var btn=Button.new();
		btn.size=Vector2(40,40);
		btn.position=node.position-btn.size/2;
		
		var color: Color;
		match node.node_type:
			MapNodeData.NodeType.START:
				color=Color.GRAY
			MapNodeData.NodeType.BATTLE:
				color=Color.GREEN
			MapNodeData.NodeType.ELITE:
				color=Color.PURPLE
			MapNodeData.NodeType.BOSS:
				color=Color.RED
			MapNodeData.NodeType.SHOP:
				color=Color.YELLOW
			MapNodeData.NodeType.REST:
				color=Color.ORANGE
			MapNodeData.NodeType.EVENT:
				color=Color.CYAN
			MapNodeData.NodeType.JUMP:
				color=Color.BLUE
			_:
				color=Color.GRAY
		if node.completed:
			btn.modulate=color*0.3;
			btn.disabled=true;
		elif node.unlocked:
			btn.modulate=color;
			btn.disabled=false;
		else:
			btn.modulate=color*0.6;
			btn.disabled=true;
		btn.add_theme_color_override("font_color",Color.WHITE);
		btn.text=node.id;
		btn.pressed.connect(_on_node_clicked.bind(id));
		map_container.add_child(btn);

func _on_node_clicked (node_id: String):
	var node=map_data.get_node(node_id);
	if !node:
		return;
	if !(node.unlocked && !node.completed):
		return;
	MapSystem.instance.set_current_node(node_id);
	var battle=load("res://scenes/battle/Battle.tscn").instantiate();
	get_tree().root.add_child(battle);

func _input(event):
	if (event is InputEventMouseButton) && (event.button_index==MOUSE_BUTTON_LEFT):
		if event.pressed:
			is_dragging=1;
			drag_start=event.position;
			container_start=map_container.position.x;
			Input.set_default_cursor_shape(Input.CURSOR_DRAG);
		else:
			is_dragging=0;
			Input.set_default_cursor_shape(Input.CURSOR_ARROW);
	elif (event is InputEventMouseMotion) && (is_dragging):
		if !(Input.get_mouse_button_mask() & MOUSE_BUTTON_LEFT):
			is_dragging=0;
			Input.set_default_cursor_shape(Input.CURSOR_ARROW);
			return;
		var delta=event.position.x-drag_start.x;
		var now_x=container_start+delta;
		map_container.position.x=now_x;
