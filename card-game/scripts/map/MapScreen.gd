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
	# 创建容器
	map_container = Control.new()
	add_child(map_container)
	
	# 生成第一层地图
	_load_current_map()
	var debug_btn = Button.new()
	debug_btn.text = "下一层 (调试)"
	debug_btn.position = Vector2(10, 10)
	debug_btn.pressed.connect(_on_debug_next_layer)
	add_child(debug_btn)

func _on_debug_next_layer():
	if MapManager.instance == null:
		return
	MapManager.instance.go_to_next_layer()
	_load_current_map()
func _load_current_map():
	if MapManager.instance == null:
		print("错误：MapManager 未初始化")
		return
	
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

func _on_node_clicked(node_id: String):
	var node = map_data.get_node(node_id)
	if not node:
		return
	if not (node.unlocked and not node.completed):
		return
	
	node.completed = true
	for next_id in node.edges:
		var next_node = map_data.get_node(next_id)
		if next_node:
			next_node.unlocked = true
	
	draw_map()
	
	# TODO: 进入战斗
	var battle = load("res://scenes/battle/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)

# 拖拽查看
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start = event.position
			container_start = map_container.position.x
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		else:
			is_dragging = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	elif event is InputEventMouseMotion and is_dragging:
		if not (Input.get_mouse_button_mask() & MOUSE_BUTTON_LEFT):
			is_dragging = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			return
		var delta = event.position.x - drag_start.x
		var now_x = container_start + delta
		map_container.position.x = now_x
