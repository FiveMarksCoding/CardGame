extends Area2D;
class_name Enemy;

var data: EnemyData=null;
# 节点
var sprite: Sprite2D=null;
var hp_bar: ProgressBar=null;
var intent_container: Control=null;
var name_label: Label=null;
var intent_items: Array[Control]=[];
# 信号
signal intent_selected(enemy: Enemy,index: int);
signal died(enemy: Enemy);
# 意图组缓存
var _cached_intents: Array=[];

func _ready():
	# hitbox;
	var hitbox=CollisionShape2D.new();
	var shape=RectangleShape2D.new();
	shape.size=Vector2(80, 80);
	hitbox.shape=shape;
	add_child(hitbox);
	# 鼠标检测
	mouse_entered.connect(_on_mouse_entered);
	mouse_exited.connect(_on_mouse_exited);
func setup (enemy_data: EnemyData):
	data=enemy_data;
	_build_visuals();
	_update_health_display();
	generate_new_intents();
# 生成新回合的意图（从 EnemyData 获取）
func generate_new_intents() -> void:
	_cached_intents = data.get_intent_group()
	_update_intents_display()
func _build_visuals():
	sprite=Sprite2D.new();
	var rect_texture=PlaceholderTexture2D.new();
	rect_texture.size=Vector2(60, 80);
	sprite.texture=rect_texture;
	sprite.modulate=Color(0.8, 0.2, 0.2);  # 红色占位
	add_child(sprite);
	name_label=Label.new();
	name_label.text=data.name;
	name_label.add_theme_font_size_override("font_size",16);
	name_label.add_theme_color_override("font_color",Color.WHITE);
	name_label.position=Vector2(-25,-100);
	add_child(name_label);
	hp_bar=ProgressBar.new();
	hp_bar.min_value=0;
	hp_bar.max_value=data.max_hp;
	hp_bar.value=data.current_hp;
	hp_bar.size=Vector2(60,10);
	hp_bar.position=Vector2(-30,-70);
	hp_bar.show_percentage=0;   # 关闭默认百分比显示
	var hp_text=Label.new();
	hp_text.name="HpText";
	hp_text.text="%d/%d" % [data.current_hp, data.max_hp];
	hp_text.add_theme_font_size_override("font_size",12);
	hp_text.add_theme_color_override("font_color", Color.WHITE);
	hp_text.position=Vector2(0,4);   # 略微偏移让文字居中
	hp_text.size=Vector2(60, 14);
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	hp_bar.add_child(hp_text);  # 作为进度条的子节点，随进度条移动
	# 用样式覆盖颜色
	var style=StyleBoxFlat.new();
	style.bg_color=Color(0.2,0.2,0.2);
	hp_bar.add_theme_stylebox_override("background",style);
	var fill_style=StyleBoxFlat.new()
	fill_style.bg_color=Color(0.2, 0.8, 0.2);
	hp_bar.add_theme_stylebox_override("fill",fill_style);
	add_child(hp_bar);
	intent_container=Control.new();
	intent_container.position=Vector2(70,-80);
	intent_container.size=Vector2(120,160);
	add_child(intent_container);
func _create_intent_item (intent: Intent, index: int) -> Control:
	var panel=Panel.new();
	panel.size=Vector2(100,26);
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;
	var style=StyleBoxFlat.new();
	style.bg_color=_get_intent_color(intent.type);
	style.set_corner_radius_all(4);
	panel.add_theme_stylebox_override("panel",style);
	var label=Label.new();
	label.text=intent.get_description();
	label.add_theme_font_size_override("font_size",12);
	label.add_theme_color_override("font_color",Color.WHITE);
	label.position=Vector2(4,4);
	label.size=Vector2(92, 18);
	panel.add_child(label)
	panel.mouse_entered.connect(_on_intent_hovered.bind(index,1));
	panel.mouse_exited.connect(_on_intent_hovered.bind(index,0));
	panel.gui_input.connect(_on_intent_clicked.bind(index));
	return panel;
func _get_intent_color (type: Intent.Type) -> Color:
	match type:
		Intent.Type.ATTACK:
			return Color(0.8, 0.2, 0.2)   # 红色
		Intent.Type.DEFEND:
			return Color(0.2, 0.4, 0.8)   # 蓝色
		Intent.Type.BUFF:
			return Color(0.8, 0.7, 0.1)   # 金色
		Intent.Type.DEBUFF:
			return Color(0.5, 0.1, 0.6)   # 紫色
		Intent.Type.HEAL:
			return Color(0.2, 0.8, 0.3)   # 绿色
		_:
			return Color(0.5, 0.5, 0.5)   # 灰色
func _on_intent_hovered (index: int, entered: bool):
	if index<intent_items.size():
		var item=intent_items[index]
		item.modulate=Color(1.3, 1.3, 1.3) if entered else Color.WHITE
func _on_intent_clicked(event: InputEvent, index: int):
	if event is InputEventMouseButton && event.pressed && event.button_index==MOUSE_BUTTON_LEFT:
		intent_selected.emit(self,index);
func _on_mouse_entered():
	modulate=Color(1.1, 1.1, 1.1);
func _on_mouse_exited():
	modulate=Color.WHITE;
func _update_health_display():
	if hp_bar:
		hp_bar.value=data.current_hp;
		var hp_text=hp_bar.get_node("HpText");
		if hp_text:
			hp_text.text="%d/%d"%[data.current_hp,data.max_hp];
func take_damage (amount: int):
	data.current_hp-=amount;
	if data.current_hp<0:
		data.current_hp=0;
	_update_health_display();
	# 闪红反馈
	modulate=Color.RED;
	await get_tree().create_timer(0.1).timeout;
	modulate=Color.WHITE;
	if data.current_hp<=0:
		died.emit(self);
# 接口
func is_dead () -> bool:
	return data.current_hp<=0;
func get_intent_count() -> int:
	return _cached_intents.size()
func get_intent_data(index: int) -> Intent:
	if index >= 0 and index < _cached_intents.size():
		return _cached_intents[index]
	return null
func replace_intent(index: int, new_intent: Intent):
	if index >= 0 and index < _cached_intents.size():
		_cached_intents[index] = new_intent
		_update_intents_display() 
func remove_intent(index: int):
	if index >= 0 and index < _cached_intents.size():
		_cached_intents.remove_at(index)
		_update_intents_display()
# 用当前缓存更新 UI
func _update_intents_display():
	for child in intent_container.get_children():
		child.queue_free()
	intent_items.clear()
	var y_offset = 0
	for i in range(_cached_intents.size()):
		var intent_data = _cached_intents[i]
		var item = _create_intent_item(intent_data, i)
		item.position = Vector2(0, y_offset)
		intent_container.add_child(item)
		intent_items.append(item)
		y_offset += 30
func execute_intents () -> Array:
	var results: Array=[];
	var intents=_cached_intents;  # 使用当前缓存
	for intent in intents:
		var result=execute_one(intent);
		results.append(result);
	# 执行后清空缓存并更新显示
	_cached_intents.clear();
	_update_intents_display();
	return results;
func execute_one (intent: Intent) -> Dictionary:
	var result = {
		"type": intent.type,
		"value": intent.value,
		"times": intent.times,
		"success": true
	};
	match intent.type:
		Intent.Type.ATTACK:
			# 攻击：返回伤害值，由 BattleManager 处理扣血
			result["damage"]=intent.value*intent.times;
			print("%s 攻击 %d 次，每次 %d 伤害" % [data.name, intent.times, intent.value])
			
		Intent.Type.DEFEND:
			# 防御：给自己加格挡（暂时只打印，实际由 BattleManager 处理）
			result["block"]=intent.value*intent.times;
			print("%s 获得 %d 点格挡" % [data.name, result["block"]])
			
		Intent.Type.BUFF:
			# 增益：给自己加力量（暂时只打印）
			result["strength"]=intent.value;
			print("%s 获得 %d 点力量" % [data.name, intent.value])
			
		Intent.Type.HEAL:
			# 治疗：给自己回血
			var heal_amount=intent.value*intent.times;
			data.current_hp=min(data.current_hp+heal_amount,data.max_hp);
			result["heal"]=heal_amount;
			print("%s 治疗 %d 点生命" % [data.name, heal_amount])
			
		_:
			print("%s 执行未知意图.这啥玩意" % data.name)
			result["success"]=0;
	return result;
