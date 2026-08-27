extends CanvasLayer;
class_name BattleUI;

var _battle_manager: BattleManager=null;
var _hp_label: Label=null;
var _block_label: Label=null;
var _end_turn_btn: Button=null;
var _turn_label: Label=null;

func _ready ():
	# 延迟一帧确保 BattleManager 已就绪
	await get_tree().process_frame
	_battle_manager=_get_battle_manager();
	if _battle_manager:
		_connect_signals();
		_build_ui();
		_update_ui();
	else:
		print("BattleUI: 找不到 BattleManager");
func _get_battle_manager () -> BattleManager:
	var p=get_parent();
	while p:
		if p.has_node("BattleManager"):
			return p.get_node("BattleManager") as BattleManager;
		p=p.get_parent();
	return null;
func _connect_signals ():
	if !_battle_manager:
		return ;
	_battle_manager.player_health_changed.connect(_on_health_changed)
	_battle_manager.player_block_changed.connect(_on_block_changed)
	_battle_manager.turn_started.connect(_on_turn_started)
func _build_ui():
	# 1. 背景面板（左下角玩家信息）
	var panel = Panel.new()
	panel.size = Vector2(180, 70)
	panel.position = Vector2(20, 400)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	# 2. 生命值文本
	_hp_label = Label.new()
	_hp_label.position = Vector2(15, 15)
	_hp_label.size = Vector2(150, 30)
	_hp_label.add_theme_font_size_override("font_size", 22)
	_hp_label.add_theme_color_override("font_color", Color.RED)
	_hp_label.text = "100/100"
	panel.add_child(_hp_label)
	# 3. 格挡值文本
	_block_label = Label.new()
	_block_label.position = Vector2(15, 45)
	_block_label.size = Vector2(150, 20)
	_block_label.add_theme_font_size_override("font_size", 16)
	_block_label.add_theme_color_override("font_color", Color.CYAN)
	_block_label.text = "🛡 0"
	panel.add_child(_block_label)
	# 4. 回合计数器
	_turn_label = Label.new()
	_turn_label.position = Vector2(20, 500)
	_turn_label.size = Vector2(200, 30)
	_turn_label.add_theme_font_size_override("font_size", 18)
	_turn_label.add_theme_color_override("font_color", Color.WHITE)
	_turn_label.text = "回合 0"
	add_child(_turn_label)
	# 5. 结束回合按钮
	_end_turn_btn = Button.new()
	_end_turn_btn.text = "结束回合"
	_end_turn_btn.size = Vector2(140, 40)
	_end_turn_btn.pressed.connect(_on_end_turn_pressed);
	# 放在右下角（相对于场景大小，这里硬编码 1200,650）
	_end_turn_btn.position=Vector2(1200-160,600-80);
	add_child(_end_turn_btn);
func _update_ui():
	if not _battle_manager:
		return
	_on_health_changed(_battle_manager.player_health, _battle_manager.player_max_health)
	_on_block_changed(_battle_manager.player_block)
	_on_turn_started(_battle_manager.turn_counts)

func _on_health_changed(new_health: int, max_health: int):
	if _hp_label:
		_hp_label.text = "❤ %d/%d" % [new_health, max_health]

func _on_block_changed(new_block: int):
	if _block_label:
		_block_label.text = "🛡 %d" % new_block

func _on_turn_started(turn_count: int):
	if _end_turn_btn:
		_end_turn_btn.disabled=0;
	if _turn_label:
		_turn_label.text="回合 %d" % turn_count

func _on_end_turn_pressed():
	if _end_turn_btn:
		_end_turn_btn.disabled=1;
	if _battle_manager:
		_battle_manager.end_player_turn()
