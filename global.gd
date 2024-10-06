extends Node

var num_keys = 0
var key_text_label : Label


func playSound(key : String):
	var player = self.get_node(key)
	if player:
		player.play()
