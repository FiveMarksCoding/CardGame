extends Control;
class_name EnergyUI;

const BALL_RADIUS: int=16;
const BALL_SPACING: int=4;
const ENERGY_BALL_SIZE: int=32;
var _energy_balls: Array=[];
var _battle_system: BattleSystem=null;

func _ready ():
	await get_tree().process_frame
	_battle_system=_get_battle_system();
	if _battle_system:
		_battle_system.energy_changed.connect(_update_energy_ui);
		_update_energy_ui();

func _get_battle_system () -> BattleSystem:
	var p=get_parent();
	if p==null:
		return null;
	var pp=p.get_parent();
	if pp==null:
		return null;
	if pp.has_node("BattleManager"):
		return pp.get_node("BattleManager") as BattleSystem;
	return null;

func _update_energy_ui ():
	if not _battle_system:
		return;
	var queue=_battle_system.get_energy_queue();
	_rebuild_balls(queue);

func _rebuild_balls (queue: Array):
	for i in _energy_balls:
		i.queue_free();
	_energy_balls.clear();
	if queue.is_empty():
		return
	var total_width=queue.size()*(ENERGY_BALL_SIZE+BALL_SPACING)-BALL_SPACING;
	var start_x=size.x-total_width;
	for i in range(queue.size()):
		var ball=Panel.new();
		ball.size=Vector2(ENERGY_BALL_SIZE,ENERGY_BALL_SIZE)
		ball.position=Vector2(start_x+i*(ENERGY_BALL_SIZE+BALL_SPACING),(size.y-ENERGY_BALL_SIZE)/2.0)
		var style=StyleBoxFlat.new()
		style.set_corner_radius_all(BALL_RADIUS)
		style.bg_color=_get_color_for_energy(queue[i])
		ball.add_theme_stylebox_override("panel",style)
		add_child(ball)
		_energy_balls.append(ball)

func _get_color_for_energy (energy_type: String) -> Color:
	match energy_type:
		"red":
			return Color(0.9,0.2,0.2)
		"blue":
			return Color(0.2,0.4,0.9)
		"green":
			return Color(0.2,0.8,0.3)
		"purple":
			return Color(0.6,0.2,0.8)
		"yellow":
			return Color(0.9,0.8,0.1)
		_:
			return Color(0.7,0.7,0.7)
