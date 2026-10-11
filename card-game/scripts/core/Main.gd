extends Control;
func _ready():
	# 原逻辑保留
	var map=load("res://scenes/screens/MapScreen.tscn").instantiate();
	add_child(map);
	
	# --- 临时调试按钮：直接开战斗 ---
	var dbg = Button.new()
	dbg.text = "调试：进入战斗"
	dbg.position = Vector2(10, 60)
	dbg.pressed.connect(_on_debug_battle)
	add_child(dbg)

func _on_debug_battle():
	var battle=load("res://scenes/battle/Battle.tscn").instantiate();
	get_tree().root.add_child(battle);
