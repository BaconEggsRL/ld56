extends Node

var num_keys = 0

var key_text_label : Label
var interactions : Node2D


func resetGlobals() -> void:
	print("reset")
	num_keys = 0

func playSound(key : String):
	var sound_player = self.get_node(key)
	if sound_player:
		sound_player.play()

func makeBoulder(pos: Vector2, min_x: float, max_x: float) -> void:
	var boulder_scene = preload("res://boulder.tscn").instantiate()
	boulder_scene.position = pos
	boulder_scene.min_x = min_x
	boulder_scene.max_x = max_x
	interactions.get_node("boulders").add_child(boulder_scene)
