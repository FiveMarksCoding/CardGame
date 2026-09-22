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
	GlobalSignals.instance.battle_victory.connect(_on_battle_victory);
	# 创建容器
	map_container=Control.new();
	add_child(map_container);
	# 连接战斗胜利信号（如果战斗场景已加载，信号会通过全局传递）
	# 使用自动加载或信号总线
	_load_current_map();
	
	# 调试按钮
	var debug_btn=Button.new();
	debug_btn.text="下一层 (调试)";
	debug_btn.position=Vector2(10,10);
	debug_btn.pressed.connect(_on_debug_next_layer);
	add_child(debug_btn);
func _on_debug_next_layer():
	if MapManager.instance==null:
		return ;
	MapManager.instance.go_to_next_layer();
	_load_current_map();
func _load_current_map():
	if MapManager.instance == null:
		print("错误：MapManager 未初始化");
		return
func _on_battle_victory():
	MapManager.instance.complete_current_node();
	_load_current_map();
	map_data = MapManager.instance.generate_current_map()
	draw_map()

func draw_map():
	for child in map_container.get_children():
		child.queue_free()
	
	if map_data == null:
		return
	
	# 绘制连接线
	for id in map_data.nodes:
		var node = map_data.nodes[id]
		for next_id in node.edges:
			var next_node = map_data.nodes[next_id]
			if next_node == null:
				continue
			var line = Line2D.new()
			line.add_point(node.position)
			line.add_point(next_node.position)
			line.width = 2.0
			line.default_color = Color.GRAY
			map_container.add_child(line)
	
	# 绘制节点按钮
	for id in map_data.nodes:
		var node = map_data.nodes[id]
		var btn = Button.new()
		btn.size = Vector2(40, 40)
		btn.position = node.position - btn.size / 2
		
		var color: Color
		match node.node_type:
			MapNodeData.NodeType.START:
				color= Color.GRAY
			MapNodeData.NodeType.BATTLE:
				color= Color.GREEN
			MapNodeData.NodeType.ELITE:
				color= Color.PURPLE
			MapNodeData.NodeType.BOSS:
				color= Color.RED
			MapNodeData.NodeType.SHOP:
				color= Color.YELLOW
			MapNodeData.NodeType.REST:
				color= Color.ORANGE
			MapNodeData.NodeType.EVENT:
				color= Color.CYAN
			MapNodeData.NodeType.JUMP:
				color= Color.BLUE
			_:
				color= Color.GRAY
		if node.completed:
			btn.modulate = color * 0.3
			btn.disabled = true
		elif node.unlocked:
			btn.modulate = color;
			btn.disabled = false
		else:
			btn.modulate = color * 0.6
			btn.disabled = true
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.text = node.id
		btn.pressed.connect(_on_node_clicked.bind(id))
		map_container.add_child(btn)

# MapScreen.gd - 修改 _on_node_clicked()
func _on_node_clicked (node_id: String):
	var node=map_data.get_node(node_id);
	if !node:
		return;
	if !(node.unlocked && !node.completed):
		return;
	MapManager.instance.set_current_node(node_id);
	# 进入战斗（根据节点类型决定战斗类型）
	var battle_type="normal";
	match node.node_type:
		MapNodeData.NodeType.ELITE:
			battle_type="elite";
		MapNodeData.NodeType.BOSS:
			battle_type="boss";
		_:
			battle_type="normal";
	# 启动战斗场景
	var battle=load("res://scenes/battle/Battle.tscn").instantiate();
	get_tree().root.add_child(battle);
# 拖拽查看
func _input(event):
	if (event is InputEventMouseButton) && (event.button_index == MOUSE_BUTTON_LEFT):
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
			return ;
		var delta=event.position.x-drag_start.x;
		var now_x=container_start+delta;
		map_container.position.x=now_x;
# 战斗胜利后
func _on_battle_victory():
	# 完成当前节点
	MapManager.instance.complete_current_node();
	# 刷新地图
	_load_current_map();
