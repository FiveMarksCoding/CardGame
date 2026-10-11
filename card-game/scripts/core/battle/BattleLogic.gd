extends RefCounted;
class_name BattleLogic;

var player_hp: int=100;
var player_max_hp: int=100;
var player_block: int=0;
var turn_count: int=0;
var is_player_turn: bool=0;
var battle_over: bool=0;
var vic: bool=1;

func start_player_turn ():
	turn_count+=1;
	is_player_turn=1;
func end_player_turn ():
	is_player_turn=0;
func add_block (n: int):
	player_block+=n;
func take_damage (n: int) -> int:
	var a=with_block(n);
	player_hp-=a;
	if player_hp<0:
		player_hp=0;
	if player_hp<=0:
		battle_over=1;
		vic=0;
	return a;
func with_block (n: int) -> int:
	if player_block>=n:
		player_block-=n;
		return 0;
	var rem=n-player_block;
	player_block=0;
	return rem;
func is_player_dead () -> bool:
	return player_hp<=0;
func mark_vic ():
	battle_over=1;
	vic=1;
