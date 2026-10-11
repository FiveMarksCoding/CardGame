extends Node;

const CARDS_DIR:="res://resources/cards/";
var _cards: Dictionary={};

func _ready():
	_load_all_cards();
func _load_all_cards():
	_cards.clear();
	var dir=DirAccess.open(CARDS_DIR);
	if dir==null:
		print("CardLib: 未找到卡牌目录 ", CARDS_DIR);
		return;
	dir.list_dir_begin();
	var file_name=dir.get_next();
	while file_name!="":
		if (!dir.current_is_dir()) && (file_name.ends_with(".tres")):
			var full_path=CARDS_DIR+file_name;
			var card=load(full_path) as CardData;
			if (card!=null) && (card.id!=""):
				_cards[card.id]=card;
			else:
				print("CardLib: 卡牌文件无效 ", file_name);
		file_name=dir.get_next();
	dir.list_dir_end();
	print("CardLib: 已加载 %d 张牌"%_cards.size());
# 对外接口
func get_card (id: String):
	return _cards.get(id,null);
func get_all_ids () -> Array:
	return _cards.keys();
func get_random_cards (n: int) -> Array:
	var ids=_cards.keys();
	ids.shuffle();
	return ids.slice(0,n);
