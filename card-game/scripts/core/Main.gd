extends Control

func _ready ():
	var map=load("res://scenes/screens/MapScreen.tscn").instantiate();
	add_child(map);
	
