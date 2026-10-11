extends Resource;
class_name CardData;

@export var id: String="";
@export var card_name: String="";
@export var cost: int=0;
@export var card_type: String="attack";   # "attack", "skill", "power"
@export var damage: int=0;
@export var block: int=0;
@export var needs_target: bool=0;
@export var description: String="";
@export var card_color: String="neutral"  # "neutral", "red", "blue", "green", "purple", "yellow"
@export var energy_re: Array=[];
