extends RefCounted;
class_name StandardMapGenerator;

var config:MapGenerationConfig=null;
const ADD_PERCENT:float=0.4;

func generate(_x:MapGenerationConfig)->MapData:
	config=_x;
	var rule=config.custom_rules.get("special_rule","");
	
	# 第六层：三条独立路径
	if rule=="three_independent_paths":
		return _generate_three_independent_paths_map(MapData.new());
	
	# 第七层：五节点固定结构（起点→商店→休息→BOSS→跳转）
	if rule=="four_nodes":
		return _generate_four_nodes_map(MapData.new());
	
	# 标准生成流程（其他层）
	var map=MapData.new();
	var paths=_generate_paths();
	var rows=_build_nodes_from_paths(paths);
	
	# 添加普通节点
	for i in range(rows.size()):
		for j in range(rows[i].size()):
			var nd=rows[i][j];
			var pos:Vector2;
			var is_diamond=config.custom_rules.get("diamond_layout",false);
			var is_circle=config.custom_rules.get("circle_layout",false);
			if is_diamond:
				var total_rows=rows.size();
				var center_row=(total_rows-1)/2.0;
				var distance=abs(i-center_row);
				var width_factor=1.0-(distance/center_row)*0.7 if center_row>0 else 1.0;
				var col_span=500*max(width_factor,0.3);
				var node_count=rows[i].size();
				var spacing=col_span/(node_count+1) if node_count>0 else 0;
				var start_y=(500-col_span)/2;
				var x=i*120+50;
				var y=start_y+(j+1)*spacing;
				pos=Vector2(x,y);
			elif is_circle:
				var total_rows=rows.size();
				var center_x=400;
				var center_y=300;
				var max_radius=300;
				var min_radius=60;
				var row_ratio=float(i)/(total_rows-1) if total_rows>1 else 0;
				var radius=min_radius+(max_radius-min_radius)*row_ratio;
				var node_count=rows[i].size();
				var angle_step=2*PI/node_count if node_count>0 else 0;
				var angle=j*angle_step;
				var x=center_x+radius*cos(angle);
				var y=center_y+radius*sin(angle);
				pos=Vector2(x,y);
			else:
				pos=Vector2(i*120+50,j*80+50);
			var node=MapData.MapNode.new(nd.id,nd.node_type,pos);
			if i==0 && j==0:
				node.unlocked=true;
				node.completed=false;
			map.add_node(node);
	
	# 单独添加BOSS节点
	if config.has_boss:
		var boss_row=config.row_count-2;
		var boss_id="%d_0"%boss_row;
		var prev_row=boss_row-1;
		var y_center=50;
		if map.nodes.size()>0:
			var y_sum=0;
			var y_count=0;
			for id in map.nodes.keys():
				var parts=id.split("_");
				var row=int(parts[0]);
				if row==prev_row:
					var node=map.nodes[id];
					y_sum+=node.position.y;
					y_count+=1;
			if y_count>0:
				y_center=y_sum/y_count;
		var boss_pos=Vector2(boss_row*120+50,y_center);
		var boss_node=MapData.MapNode.new(boss_id,MapNodeData.NodeType.BOSS,boss_pos);
		boss_node.unlocked=false;
		boss_node.completed=false;
		map.add_node(boss_node);
	
	# 单独添加跳转节点
	if config.has_jump:
		var jump_row=config.row_count-1;
		var jump_count=randi_range(config.min_jump_nodes,config.max_jump_nodes);
		var center_y=50;
		var prev_row=jump_row-1;
		if config.has_boss:
			var boss_row=config.row_count-2;
			var boss_id="%d_0"%boss_row;
			if map.nodes.has(boss_id):
				center_y=map.nodes[boss_id].position.y;
		else:
			var y_sum=0;
			var y_count=0;
			for id in map.nodes.keys():
				var parts=id.split("_");
				var row=int(parts[0]);
				if row==prev_row:
					var node=map.nodes[id];
					y_sum+=node.position.y;
					y_count+=1;
			if y_count>0:
				center_y=y_sum/y_count;
		var spacing=50;
		var total_height=(jump_count-1)*spacing;
		var start_y=center_y-total_height/2;
		for j in range(jump_count):
			var jump_id="%d_%d"%[jump_row,j];
			var jump_pos=Vector2(jump_row*120+50,start_y+j*spacing);
			var jump_node=MapData.MapNode.new(jump_id,MapNodeData.NodeType.JUMP,jump_pos);
			jump_node.unlocked=false;
			jump_node.completed=false;
			map.add_node(jump_node);
	
	# 建立连接
	_build_connections_from_paths(paths,map);
	
	# BOSS连接
	if config.has_boss:
		var boss_row=config.row_count-2;
		var boss_id="%d_0"%boss_row;
		if map.nodes.has(boss_id):
			var prev_row=boss_row-1;
			for id in map.nodes.keys():
				var parts=id.split("_");
				var row=int(parts[0]);
				if row==prev_row:
					map.add_connection(id,boss_id);
			if config.has_jump:
				var jump_row=config.row_count-1;
				for j in range(config.max_jump_nodes):
					var jump_id="%d_%d"%[jump_row,j];
					if map.nodes.has(jump_id):
						map.add_connection(boss_id,jump_id);
	
	_fix_isolated_nodes(map, paths);
	
	return map;

# ============ 第六层：三条独立路径 ============
func _generate_three_independent_paths_map(map:MapData)->MapData:
	var path_count=3;
	var row_count=config.row_count;
	
	var col_ranges=[
		[0,1],
		[2,3],
		[4,5]
	];
	
	var path_node_ids=[[], [], []];
	
	# 起点
	var start_id="0_0";
	var start_pos=Vector2(0*120+50, 80);
	var start_node=MapData.MapNode.new(start_id, MapNodeData.NodeType.START, start_pos);
	start_node.unlocked=true;
	start_node.completed=false;
	map.add_node(start_node);
	
	# 生成三条路径的节点（第1行到第12行）
	for p in range(path_count):
		var min_col=col_ranges[p][0];
		var max_col=col_ranges[p][1];
		var current_col=min_col + randi()%(max_col-min_col+1);
		var node_ids=[];
		
		for row in range(1, row_count-2):
			var col_range_size=max_col-min_col+1;
			var col=min_col + randi()%col_range_size;
			current_col=col;
			var id="%d_%d"%[row, col];
			var pos=Vector2(row*120+50, col*80+50);
			var node_type=_pick_node_type(row, col);
			var node=MapData.MapNode.new(id, node_type, pos);
			node.unlocked=false;
			node.completed=false;
			map.add_node(node);
			node_ids.append(id);
		
		path_node_ids[p]=node_ids;
	
	# BOSS居中
	var prev_row=row_count-3;
	var y_sum=0;
	var y_count=0;
	for id in map.nodes.keys():
		var parts=id.split("_");
		var row=int(parts[0]);
		if row==prev_row:
			var node=map.nodes[id];
			y_sum+=node.position.y;
			y_count+=1;
	var boss_y=50;
	if y_count>0:
		boss_y=y_sum/y_count;
	
	var boss_row=row_count-2;
	var boss_id="%d_0"%boss_row;
	var boss_pos=Vector2(boss_row*120+50, boss_y);
	var boss_node=MapData.MapNode.new(boss_id, MapNodeData.NodeType.BOSS, boss_pos);
	boss_node.unlocked=false;
	boss_node.completed=false;
	map.add_node(boss_node);
	
	# 跳转（1个）
	var jump_row=row_count-1;
	var jump_id="%d_0"%jump_row;
	var jump_pos=Vector2(jump_row*120+50, boss_y+50);
	var jump_node=MapData.MapNode.new(jump_id, MapNodeData.NodeType.JUMP, jump_pos);
	jump_node.unlocked=false;
	jump_node.completed=false;
	map.add_node(jump_node);
	
	# 连接
	for p in range(path_count):
		if path_node_ids[p].size()>0:
			map.add_connection(start_id, path_node_ids[p][0]);
	
	for p in range(path_count):
		for i in range(path_node_ids[p].size()-1):
			map.add_connection(path_node_ids[p][i], path_node_ids[p][i+1]);
	
	for p in range(path_count):
		if path_node_ids[p].size()>0:
			var last_id=path_node_ids[p][path_node_ids[p].size()-1];
			map.add_connection(last_id, boss_id);
	
	map.add_connection(boss_id, jump_id);
	
	return map;

# ============ 第七层：五节点固定结构 ============
func _generate_four_nodes_map(map:MapData)->MapData:
	# 第0行：起点
	var start_id="0_0";
	var start_pos=Vector2(0*120+50, 200);
	var start_node=MapData.MapNode.new(start_id, MapNodeData.NodeType.START, start_pos);
	start_node.unlocked=true;
	start_node.completed=false;
	map.add_node(start_node);
	
	# 第1行：商店
	var shop_id="1_0";
	var shop_pos=Vector2(1*120+50, 200);
	var shop_node=MapData.MapNode.new(shop_id, MapNodeData.NodeType.SHOP, shop_pos);
	shop_node.unlocked=false;
	shop_node.completed=false;
	map.add_node(shop_node);
	
	# 第2行：休息处（火堆）
	var rest_id="2_0";
	var rest_pos=Vector2(2*120+50, 200);
	var rest_node=MapData.MapNode.new(rest_id, MapNodeData.NodeType.REST, rest_pos);
	rest_node.unlocked=false;
	rest_node.completed=false;
	map.add_node(rest_node);
	
	# 第3行：BOSS
	var boss_id="3_0";
	var boss_pos=Vector2(3*120+50, 200);
	var boss_node=MapData.MapNode.new(boss_id, MapNodeData.NodeType.BOSS, boss_pos);
	boss_node.unlocked=false;
	boss_node.completed=false;
	map.add_node(boss_node);
	
	# 第4行：跳转（1个）
	var jump_id="4_0";
	var jump_pos=Vector2(4*120+50, 200);
	var jump_node=MapData.MapNode.new(jump_id, MapNodeData.NodeType.JUMP, jump_pos);
	jump_node.unlocked=false;
	jump_node.completed=false;
	map.add_node(jump_node);
	
	# 连接
	map.add_connection(start_id, shop_id);
	map.add_connection(shop_id, rest_id);
	map.add_connection(rest_id, boss_id);
	map.add_connection(boss_id, jump_id);
	
	return map;

# ============ 以下为通用函数 ============
func _generate_paths()->Array:
	var base_path_count=randi_range(config.min_nodes_per_row,config.max_nodes_per_row);
	var multiplier=config.custom_rules.get("path_multiplier",1.0);
	var path_count=max(2,int(round(base_path_count*multiplier)));
	var paths=[];
	var used_cols_per_row={};
	var start_cols=range(config.max_nodes_per_row);
	start_cols.shuffle();
	
	var last_middle_row=config.row_count-2;
	if config.has_boss:
		last_middle_row=config.row_count-3;
	
	for p in range(path_count):
		var start_col=start_cols[p] if p<start_cols.size() else 0;
		var path=_generate_single_path(used_cols_per_row,p,start_col,last_middle_row);
		if path.size()>0:
			paths.append(path);
			for step in path:
				if !used_cols_per_row.has(step.row):
					used_cols_per_row[step.row]=[];
				if !(step.col in used_cols_per_row[step.row]):
					used_cols_per_row[step.row].append(step.col);
	
	if paths.size()>0 and paths[0].size()>0:
		paths[0][0]=MapNodeData.new("0_0",MapNodeData.NodeType.START,0,0);
	
	return paths;

func _generate_single_path(used_cols_per_row:Dictionary,path_index:int,start_col:int,last_middle_row:int)->Array:
	var path=[];
	var max_col=config.max_nodes_per_row-1;
	var start=MapNodeData.new("0_0",MapNodeData.NodeType.START,0,0);
	var current_col=start_col;
	path.append(start);
	
	for i in range(1,last_middle_row+1):
		var used_in_this_row=used_cols_per_row.get(i,[]);
		var min_col=max(0,current_col-1);
		var max_col_available=min(max_col,current_col+1);
		var available_cols=[];
		for c in range(min_col,max_col_available+1):
			if !(c in used_in_this_row):
				available_cols.append(c);
		if available_cols.is_empty():
			for c in range(min_col,max_col_available+1):
				if !(c in available_cols):
					available_cols.append(c);
		var col=available_cols[randi()%available_cols.size()];
		current_col=col;
		var node_type=_pick_node_type(i,col);
		var node=MapNodeData.new("%d_%d"%[i,col],node_type,i,col);
		path.append(node);
	
	return path;

func _build_nodes_from_paths(paths:Array)->Array:
	var rows=[];
	var max_row=0;
	for path in paths:
		for step in path:
			if step.row>max_row:
				max_row=step.row;
	
	if max_row==0:
		max_row=config.row_count-3;
		if max_row<1:
			max_row=1;
	
	var row_count=max_row+1;
	
	for i in range(row_count):
		var cols_used=[];
		for path in paths:
			for step in path:
				if step.row==i and !(step.col in cols_used):
					cols_used.append(step.col);
		cols_used.sort();
		
		if cols_used.is_empty():
			var fallback_type=MapNodeData.NodeType.BATTLE;
			if i==0:
				fallback_type=MapNodeData.NodeType.START;
			var fallback_node=MapNodeData.new("%d_0"%i,fallback_type,i,0);
			rows.append([fallback_node]);
			continue;
		
		var row_nodes=[];
		for idx in range(cols_used.size()):
			var original_col=cols_used[idx];
			var node_type=MapNodeData.NodeType.BATTLE;
			for path in paths:
				for step in path:
					if step.row==i and step.col==original_col:
						node_type=step.node_type;
						break;
			var node=MapNodeData.new("%d_%d"%[i,idx],node_type,i,idx);
			row_nodes.append(node);
		rows.append(row_nodes);
	
	return rows;

func _build_connections_from_paths(paths:Array,map:MapData):
	for path in paths:
		for i in range(path.size()-1):
			var from_node=path[i];
			var to_node=path[i+1];
			map.add_connection(from_node.id,to_node.id);
	
	var node_map={};
	for id in map.nodes.keys():
		var node=map.nodes[id];
		var parts=id.split("_");
		var row=int(parts[0]);
		var col=int(parts[1]);
		if !node_map.has(row):
			node_map[row]={};
		node_map[row][col]=id;
	
	for row in range(config.row_count-1):
		var current_row=node_map.get(row,{});
		var next_row=node_map.get(row+1,{});
		if current_row.is_empty() or next_row.is_empty():
			continue;
		var current_cols=current_row.keys();
		var next_cols=next_row.keys();
		for col in current_cols:
			if randf()>ADD_PERCENT:
				continue;
			var from_id=current_row[col];
			var connected_count=0;
			for next_col in next_cols:
				if abs(next_col-col)<=1:
					var to_id=next_row[next_col];
					if !(to_id in map.get_outgoing(from_id)):
						map.add_connection(from_id,to_id);
						connected_count+=1;
				if connected_count>=2:
					break;
	
	_ensure_connectivity(map,node_map);

func _ensure_connectivity(map:MapData,node_map:Dictionary):
	var total_rows=config.row_count;
	
	for row in range(total_rows-1):
		var current_row=node_map.get(row,{});
		var next_row=node_map.get(row+1,{});
		if current_row.is_empty() or next_row.is_empty():
			continue;
		
		var current_cols=current_row.keys();
		var next_cols=next_row.keys();
		
		for col in current_cols:
			var from_id=current_row[col];
			var has_outgoing=false;
			for next_col in next_cols:
				var to_id=next_row[next_col];
				if to_id in map.get_outgoing(from_id):
					has_outgoing=true;
					break;
			if !has_outgoing:
				var nearest_col=next_cols[0];
				for next_col in next_cols:
					if abs(next_col-col)<abs(nearest_col-col):
						nearest_col=next_col;
				var to_id=next_row[nearest_col];
				map.add_connection(from_id,to_id);
		
		for next_col in next_cols:
			var to_id=next_row[next_col];
			var has_incoming=false;
			for col in current_cols:
				var from_id=current_row[col];
				if to_id in map.get_outgoing(from_id):
					has_incoming=true;
					break;
			if !has_incoming:
				var nearest_col=current_cols[0];
				for col in current_cols:
					if abs(col-next_col)<abs(nearest_col-next_col):
						nearest_col=col;
				var from_id=current_row[nearest_col];
				map.add_connection(from_id,to_id);

func _fix_isolated_nodes(map:MapData, paths:Array=[]):
	for id in map.nodes.keys():
		var node=map.nodes[id];
		var parts=id.split("_");
		var row=int(parts[0]);
		var col=int(parts[1]);
		
		if node.node_type==MapNodeData.NodeType.START:
			continue;
		if node.node_type==MapNodeData.NodeType.BOSS or node.node_type==MapNodeData.NodeType.JUMP:
			continue;
		
		var has_outgoing=false;
		var outgoing=map.get_outgoing(id);
		if outgoing.size()>0:
			has_outgoing=true;
		
		var has_incoming=false;
		for other_id in map.nodes.keys():
			if other_id!=id:
				var other_outgoing=map.get_outgoing(other_id);
				if id in other_outgoing:
					has_incoming=true;
					break;
		
		if !has_outgoing and row<config.row_count-1:
			var next_row=row+1;
			var target_id=null;
			for other_id in map.nodes.keys():
				var other_parts=other_id.split("_");
				var other_row=int(other_parts[0]);
				if other_row==next_row:
					target_id=other_id;
					break;
			if target_id!=null:
				map.add_connection(id,target_id);
		
		if !has_incoming and row>0:
			var prev_row=row-1;
			var source_id=null;
			for other_id in map.nodes.keys():
				var other_parts=other_id.split("_");
				var other_row=int(other_parts[0]);
				if other_row==prev_row:
					source_id=other_id;
					break;
			if source_id!=null:
				map.add_connection(source_id,id);

func _pick_node_type(i:int,j:int)->MapNodeData.NodeType:
	if i==0 && j==0:
		return MapNodeData.NodeType.START;
	if config.has_boss && i==config.row_count-2:
		return MapNodeData.NodeType.BOSS;
	if config.has_jump && i==config.row_count-1:
		return MapNodeData.NodeType.JUMP;
	var rand_val=randf();
	var node_type:MapNodeData.NodeType;
	if rand_val<config.battle_chance:
		node_type=MapNodeData.NodeType.BATTLE;
	elif rand_val<config.battle_chance+config.elite_chance:
		node_type=MapNodeData.NodeType.ELITE;
	elif rand_val<config.battle_chance+config.elite_chance+config.shop_chance:
		node_type=MapNodeData.NodeType.SHOP;
	elif rand_val<config.battle_chance+config.elite_chance+config.shop_chance+config.rest_chance:
		node_type=MapNodeData.NodeType.REST;
	else:
		node_type=MapNodeData.NodeType.EVENT;
	if node_type==MapNodeData.NodeType.BATTLE:
		var replacement_rate=config.custom_rules.get("shop_replacement_rate",0.0);
		if randf()<replacement_rate:
			node_type=MapNodeData.NodeType.SHOP;
	return node_type;
