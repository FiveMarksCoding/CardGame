extends Control;
class_name EnergyUI;

const BALL_RADIUS: int=16;
const BALL_SPACING: int=4;
const ENERGY_BALL_SIZE: int=32;  # 直径
var _energy_balls: Array=[];
var _battlemanager: BattleManager=null;
func _ready():
	# 延迟一帧确保 BattleManager 已就绪
	print("EnergyUI _ready start")
	await get_tree().process_frame
	print("after process_frame")
	_battlemanager=_get_battle_manager();
	print("battle_manager found: ", _battlemanager != null)
	if _battlemanager:
		print("connecting signal")
		_battlemanager.energy_changed.connect(_update_energy_ui);
		print("signal comnnected")
		_update_energy_ui()
		print("initial update done")
	else:
		print("EnergyUI: 找不到 BattleManager")
func _get_battle_manager() -> BattleManager:
	var p=get_parent();
	if p==null:
		return null;
	var pp=p.get_parent();  # Battle 场景
	if pp==null:
		return null;
	# 在 Battle 场景下查找 BattleManager
	if pp.has_node("BattleManager"):
		return pp.get_node("BattleManager") as BattleManager;
	return null;
func _update_energy_ui():
	if not _battlemanager:
		return;
	var queue=_battlemanager.get_energy_queue();
	_rebuild_balls(queue);
func _rebuild_balls(queue: Array):
	for i in _energy_balls:
		i.queue_free();
	_energy_balls.clear();
	if queue.is_empty():
		return
	# 计算所有球的总宽度
	var total_width=queue.size()*(ENERGY_BALL_SIZE+BALL_SPACING)-BALL_SPACING;
	# 右对齐：最右侧固定在容器右边缘
	var start_x=size.x-total_width;
	for i in range(queue.size()):
		var ball=Panel.new();
		ball.size = Vector2(ENERGY_BALL_SIZE, ENERGY_BALL_SIZE)
		ball.position = Vector2(start_x + i * (ENERGY_BALL_SIZE + BALL_SPACING), (size.y - ENERGY_BALL_SIZE) / 2.0)
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(BALL_RADIUS)
		style.bg_color = _get_color_for_energy(queue[i])
		ball.add_theme_stylebox_override("panel", style)
		
		add_child(ball)
		_energy_balls.append(ball)
func _get_color_for_energy(energy_type: String) -> Color:
	match energy_type:
		"red":
			return Color(0.9, 0.2, 0.2)
		"blue":
			return Color(0.2, 0.4, 0.9)
		"green":
			return Color(0.2, 0.8, 0.3)
		"purple":
			return Color(0.6, 0.2, 0.8)
		"yellow":
			return Color(0.9, 0.8, 0.1)
		_:
			return Color(0.7, 0.7, 0.7)
