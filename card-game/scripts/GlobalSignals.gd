extends Node;
#class_name GlobalSignals;
signal battle_victory();

static var instance: GlobalSignals=null;

func _ready ():
	instance=self;
