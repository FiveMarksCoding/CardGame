extends Control;
class_name WatchUI;

var pending_mode: int=0; # 0空闲 1红 2蓝
var _btn: Button=null;
var _lab: Label=null;
var _filter: ColorRect=null; 

func _ready ():
	visible=1;
	
	_filter=ColorRect.new();
	_filter.anchors_preset=Control.PRESET_FULL_RECT;
	_filter.size = get_viewport().get_visible_rect().size;
	_filter.mouse_filter=Control.MOUSE_FILTER_IGNORE;
	_filter.visible=0;
	add_child(_filter);
	move_child(_filter,0);
	
	_lab=Label.new();
	_lab.text="T%d" % GameState.time_charges;
	_lab.add_theme_color_override("font_color",Color.CYAN);
	_lab.position=Vector2(20,120);
	add_child(_lab);
	
	# 连接事件
	EventBus.time_charges_changed.connect(_on_charges_changed);
	EventBus.battle_started.connect(func(): visible=1);
	EventBus.run_started.connect(func(): visible=1);
	EventBus.time_target_selected.connect(_on_target_selected);
	
	_btn=Button.new();
	_btn.text="切换时间模式";
	_btn.position=Vector2(10,140);
	_btn.pressed.connect(_on_button_pressed);
	add_child(_btn);

func _on_charges_changed(new_charges: int):
	_lab.text="T%d" % new_charges;

func _on_button_pressed():
	pending_mode=(pending_mode+1)%3;
	if pending_mode==1:
		print("模式切换为: 红移(跳过)");
		_filter.color=Color(1,0,0,0.15); # 红色半透明
		_filter.visible=true;
	elif pending_mode==2:
		print("模式切换为: 蓝移(回溯)");
		_filter.color=Color(0,0,1,0.15); # 蓝色半透明
		_filter.visible=true;
	else:
		print("模式切换为: 空闲");
		_filter.visible=false;
	EventBus.time_mode_changed.emit(pending_mode);

func _on_target_selected(target_type: String, target_id: String):
	if pending_mode==0:
		return; # 没开表，点击无效
		
	# 交给 TimeService 校验扣费
	TimeService.act(pending_mode, target_type, target_id);
	pending_mode=0;
	_filter.visible=false; # 关滤镜
	EventBus.time_mode_changed.emit(0);
