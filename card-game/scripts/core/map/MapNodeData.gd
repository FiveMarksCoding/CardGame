class_name MapNodeData;
extends RefCounted;
enum NodeType {
	START,        # 起点
	BATTLE,       # 普通战斗
	ELITE,        # 精英战斗
	SHOP,         # 商店
	REST,         # 休息处
	EVENT,        # 问号事件
	BOSS,         # BOSS
	JUMP,         # 跳转事件（层间连接）
};
var id: String;                    # 节点唯一标识
var node_type: NodeType;           # 节点类型
var row: int;                      # 所在行（第几小层）
var col: int;                      # 所在列（同行中的位置）
var is_visited: bool=0             # 是否已访问
var is_reachable: bool=1           # 是否可达（当前是否可解锁）

var custom_data: Dictionary={};

func _init(p_id: String,p_type: NodeType,p_row: int,p_col: int):
	id=p_id;
	node_type=p_type;
	row=p_row;
	col=p_col;
# 获取节点显示名称
func get_display_name() -> String:
	match node_type:
		NodeType.START:
			return "起点";
		NodeType.BATTLE:
			return "战斗";
		NodeType.ELITE:
			return "精英";
		NodeType.SHOP:
			return "商店";
		NodeType.REST:
			return "休息";
		NodeType.EVENT:
			return "?";
		NodeType.BOSS:
			return "BOSS";
		NodeType.JUMP:
			return "→";
		_:
			return "未知";
