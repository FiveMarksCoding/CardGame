extends RefCounted;
class_name StandardMapGenerator;

var config:MapGenerationConfig=null;
const ADD_PERCENT:float=0.4;

func generate(_x:MapGenerationConfig)->MapData:
	config=_x;
	var map=MapData.new();
	var paths=_generate_paths();
	var rows=_build_nodes_from_paths(paths);
	
	# 添加普通节点
	for i in range(rows.size()):
		for j in range(rows[i].size()):
			var nd=rows[i][j];
			var pos:Vector2;
			var is_diamond=config.custom_rules.get("diamond_layout",false);
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
		var y_center=50;  # 默认值
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
		# 计算垂直居中位置
		var center_y=50;
		var prev_row=jump_row-1;
		# 如果有BOSS，以BOSS的Y为中心
		if config.has_boss:
			var boss_row=config.row_count-2;
			var boss_id="%d_0"%boss_row;
			if map.nodes.has(boss_id):
				center_y=map.nodes[boss_id].position.y;
		else:
			# 否则以前一行的平均Y为中心
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
		# 跳转节点垂直分散
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
	
	# 补全孤立节点
	_fix_isolated_nodes(map);
	
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
	
	return map;

func _generate_paths()->Array:
	var base_path_count=4;
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
	
	# 确保第一行有起点
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
		var j=available_cols[randi()%available_cols.size()];
		current_col=j;
		var node_type=_pick_node_type(i,j);
		var node=MapNodeData.new("%d_%d"%[i,j],node_type,i,j);
		path.append(node);
	
	return path;

func _build_nodes_from_paths(paths:Array)->Array:
	var rows=[];
	
	# 确定实际行数范围
	var max_row=0;
	for path in paths:
		for step in path:
			if step.row>max_row:
				max_row=step.row;
	
	# 如果路径为空，创建默认行
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
		
		# 如果该行没有节点，补一个
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
	# 主干连接
	for path in paths:
		for i in range(path.size()-1):
			var from_node=path[i];
			var to_node=path[i+1];
			map.add_connection(from_node.id,to_node.id);
	
	# 分支连接
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
	
	# 确保每行每个节点至少有一条出边（到下一行）和一条入边（从上一行）
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
		
		# 确保每个当前行节点至少有一条出边
		for col in current_cols:
			var from_id=current_row[col];
			var has_outgoing=false;
			for next_col in next_cols:
				var to_id=next_row[next_col];
				if to_id in map.get_outgoing(from_id):
					has_outgoing=true;
					break;
			if !has_outgoing:
				# 连接到下一行最近的节点
				var nearest_col=next_cols[0];
				for next_col in next_cols:
					if abs(next_col-col)<abs(nearest_col-col):
						nearest_col=next_col;
				var to_id=next_row[nearest_col];
				map.add_connection(from_id,to_id);
		
		# 确保每个下一行节点至少有一条入边
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

func _fix_isolated_nodes(map:MapData):
	# 检查每个节点是否有入边和出边
	for id in map.nodes.keys():
		var node=map.nodes[id];
		var parts=id.split("_");
		var row=int(parts[0]);
		var col=int(parts[1]);
		
		# 起点不需要入边，终点不需要出边
		if node.node_type==MapNodeData.NodeType.START:
			continue;
		if node.node_type==MapNodeData.NodeType.BOSS or node.node_type==MapNodeData.NodeType.JUMP:
			continue;
		
		# 检查出边
		var has_outgoing=false;
		var outgoing=map.get_outgoing(id);
		if outgoing.size()>0:
			has_outgoing=true;
		
		# 检查入边
		var has_incoming=false;
		for other_id in map.nodes.keys():
			if other_id!=id:
				var other_node=map.nodes[other_id];
				var other_outgoing=map.get_outgoing(other_id);
				if id in other_outgoing:
					has_incoming=true;
					break;
		
		# 如果没有出边，连接到下一行
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
		
		# 如果没有入边，从上一行连接过来
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
