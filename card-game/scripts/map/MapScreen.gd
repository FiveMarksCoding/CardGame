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
	map_container = Control.new()
	add_child(map_container)
	
	var config = MapGenerationConfig.new(8, false)
	config.min_jump_nodes = 2
	config.max_jump_nodes = 2
	config.min_nodes_per_row = 3
	config.max_nodes_per_row = 5
	
	var gen = StandardMapGenerator.new()
	map_data = gen.generate(config)
	
	draw_map()
func draw_map ():
	for i in map_container.get_children():
		i.queue_free();
	for id in map_data.nodes:
		var node: MapData.MapNode=map_data.nodes[id];
		for next in node.edges:
			var next_node=map_data.nodes[next];
			if next_node==null:
				continue;
			var line=Line2D.new();
			line.add_point(node.position);
			line.add_point(next_node.position);
			line.width=2.0;
			line.default_color=Color.GRAY;
			if node.completed && next_node.unlocked:
				line.default_color=Color.GOLD;
			map_container.add_child(line);
	for id in map_data.nodes:
		var node: MapData.MapNode = map_data.nodes[id];
		# 这个 node 是属于 MapData 类下的一个 MapNode
		# nodes 是 MapData 下一个字典
		var btn = Button.new();
		btn.size = Vector2(40,40);
		btn.position = node.position-(btn.size/2);
		var color = StyleBoxFlat.new();
		match node.node_type:
			0:  # START
				color.bg_color = Color.GRAY
			1:  # BATTLE
				color.bg_color = Color.GRAY
			2:  # ELITE
				color.bg_color = Color.PURPLE
			3:  # SHOP
				color.bg_color = Color.YELLOW
			4:  # REST
				color.bg_color = Color.RED
			5:  # EVENT
				color.bg_color = Color.YELLOW
			6:  # BOSS
				color.bg_color = Color.BLACK
			7:  # JUMP
				color.bg_color = Color.GRAY
			_:
				color.bg_color = Color.GRAY
		if node.completed:
			color.bg_color=color.bg_color*0.3;
			btn.disabled=1;
		elif node.unlocked:
			btn.disabled=0;
		else:
			color.bg_color=color.bg_color*0.6;
			btn.disabled=1;
		btn.modulate = color.bg_color
		btn.add_theme_color_override("font_color", Color.WHITE)  # 确保文字可见
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
	var battle = load("res://scenes/battle/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)
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
