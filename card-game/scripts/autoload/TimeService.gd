extends Node;

enum Mode { NONE, FORWARD, BACKWARD };

var charges=0;
var used_targets_this_turn=[];

var cost_table={
	"hp": 2,
	"energy": 1,
	"intent": 1,
	"deck": 2,
	"card": 1,
	"map": 3
};

func add_charge (amount: int=1):
	GameState.time_charges += amount; # 改账本
	EventBus.time_charges_changed.emit(GameState.time_charges);

func act (mode: Mode,target_type: String,target_id: String):
	# 查账
	if GameState.time_charges < cost_table.get(target_type, 99):
		print("#01 充能不足");
		return ;
	if target_id in used_targets_this_turn:
		print("#02 本回合已经用过该目标");
		return ;
		
	# 扣账
	GameState.time_charges -= cost_table.get(target_type,99);
	used_targets_this_turn.append(target_id);
	EventBus.time_charges_changed.emit(GameState.time_charges);
	EventBus.time_action_executed.emit(mode,target_type,target_id);
