extends RefCounted;
class_name StandardMapGenerator;

var config: MapGenerationConfig=null;
const ADD_PERCENT: float=0.4;
func generate(x: MapGenerationConfig) -> MapData:
	config=x;
	var map=MapData.new();
	# 生成主干路径
	var paths=_generate_paths();
	# 根据路径创建节点
	var rows=_build_nodes_from_paths(paths);
	
	# 将节点添加到 MapData
	for i in range(rows.size()):
		for j in range(rows[i].size()):
			var nd=rows[i][j];
			var pos=Vector2(i*120+50,j*80+50);
			var node=MapData.MapNode.new(nd.id,nd.node_type,pos);
			if (i==0) && (j==0):
				node.unlocked=1
				node.completed=1;
			map.add_node(node);
	# 根据路径建立连接
	_build_connections_from_paths(paths, map);
	return map;
# 路径生成
func _generate_paths() -> Array:
	# 路径数量：4
	var path_count=4;
	var paths=[];
	var used_cols_per_row={};# 每行已用的列
	var start_cols = range(config.max_nodes_per_row)  # [0, 1, 2, 3, 4]
	start_cols.shuffle()  # 打乱顺序
	for p in range(path_count):
		var start_col=start_cols[p] if p<start_cols.size() else 0;
		var path=_generate_single_path(used_cols_per_row,p,start_col);
		if path.size()>0:
			paths.append(path);
			# 记录该路径使用的列
			for step in path:
				if !used_cols_per_row.has(step.row):
					used_cols_per_row[step.row]=[];
				if !(step.col in used_cols_per_row[step.row]):
					used_cols_per_row[step.row].append(step.col);
	return paths;
# 生成一条路径
func _generate_single_path (used_cols_per_row: Dictionary,path_index: int,start_col: int) -> Array:
	var path=[];
	var max_col=config.max_nodes_per_row-1;
	var start=MapNodeData.new("0_0",MapNodeData.NodeType.START,0,0);
	var current_col=start_col;
	path.append(start);
	var last_middle_row=config.row_count-2;
	if config.has_boss:
		last_middle_row=config.row_count-3;
	for i in range(1,config.row_count-1):
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
		var j=available_cols[randi() % available_cols.size()];
		current_col=j;
		var node_type=_pick_node_type(i,j);
		var node=MapNodeData.new("%d_%d" % [i,j],node_type,i,j);
		path.append(node);
	if config.has_boss:
		var boss_row=config.row_count-2;
		var boss_type=MapNodeData.NodeType.BOSS;
		var boss_node=MapNodeData.new("%d_0" % boss_row,boss_type,boss_row,0);
		path.append(boss_node);
	var jump_row=config.row_count-1;
	# 计算当前路径应该用哪个列作为跳转节点
	var jump_col=path_index%config.max_jump_nodes;
	var jump_node=MapNodeData.new("%d_%d" % [jump_row, jump_col],MapNodeData.NodeType.JUMP,jump_row,jump_col);
	path.append(jump_node);
	return path;
# 节点构建
func _build_nodes_from_paths(paths: Array) -> Array:
	var rows=[];
	var row_count=config.row_count;
	for i in range(row_count):
		var row_nodes=[];
		# 收集该行所有路径经过的列
		var cols_used=[];
		for k in paths:
			for step in k:
				if (step.row==i) && !(step.col in cols_used):
					cols_used.append(step.col);
		# 为每个列创建节点
		for j in cols_used:
			var node_type=MapNodeData.NodeType.BATTLE;
			# 如果该节点是某条路径的一部分，使用路径中的类型
			for k in paths:
				for step in k:
					if (step.row==i) && (step.col==j):
						node_type=step.node_type
						break;
			# 如果该行还有其他列，创建分支节点
			var node=MapNodeData.new("%d_%d" % [i,j],node_type,i,j);
			row_nodes.append(node);
		# 如果该行没有节点（理论上不会发生），补一个
		if row_nodes.is_empty():
			var fallback_type=MapNodeData.NodeType.BATTLE;
			if i==0:
				fallback_type=MapNodeData.NodeType.START;
			elif i==row_count-1:
				fallback_type=MapNodeData.NodeType.JUMP if !config.has_boss else MapNodeData.NodeType.BOSS
			var node=MapNodeData.new("%d_0" % i,fallback_type,i,0);
			row_nodes.append(node);
		rows.append(row_nodes);
	return rows;
# 在路径间加边
func _build_connections_from_paths (paths: Array, map: MapData):
	# 主干连接
	for k in paths:
		for i in range(k.size() - 1):
			var from_node=k[i];
			var to_node=k[i+1];
			map.add_connection(from_node.id,to_node.id);
	# 分支连接
	var node_map={};
	for id in map.nodes.keys():
		var node=map.nodes[id];
		# 解析行列
		var parts=id.split("_");
		var i=int(parts[0]);
		var j=int(parts[1]);
		if !node_map.has(i):
			node_map[i]={};
		node_map[i][j]=id;
	for i in range(config.row_count-1):
		var current_row=node_map.get(i,{})
		var next_row=node_map.get(i+1,{});
		if current_row.is_empty() || next_row.is_empty():
			continue;
		var current_cols=current_row.keys();
		var next_cols=next_row.keys();
		# 为当前行的每个节点，连接下一行相邻列的节点
		for col in current_cols:
			if randf()>ADD_PERCENT:
				continue;
			var from_id=current_row[col]
			var connected_count=0;
			for next_col in next_cols:
				if abs(next_col-col)<=1:
					var to_id=next_row[next_col];
					# 避免重复连接
					if !(to_id in map.get_outgoing(from_id)):
						map.add_connection(from_id,to_id);
						connected_count+=1;
				if connected_count>=2:
					break;
func _pick_node_type(i: int,j: int) -> MapNodeData.NodeType:
	if (i==0) && (j==0):
		return MapNodeData.NodeType.START;
	# BOSS行（倒数第二行）
	if config.has_boss && (i==config.row_count-2):
		return MapNodeData.NodeType.BOSS
	# 跳转行（最后一行）
	if config.has_jump && (i==config.row_count-1):
		return MapNodeData.NodeType.JUMP
	# 其他类型根据概率分配
	var rand_val=randf();
	if rand_val<config.battle_chance:
		return MapNodeData.NodeType.BATTLE;
	elif rand_val < config.battle_chance+config.elite_chance:
		return MapNodeData.NodeType.ELITE;
	elif rand_val < config.battle_chance+config.elite_chance+config.shop_chance:
		return MapNodeData.NodeType.SHOP;
	elif rand_val < config.battle_chance+config.elite_chance+config.shop_chance+config.rest_chance:
		return MapNodeData.NodeType.REST;
	else:
		return MapNodeData.NodeType.EVENT;
