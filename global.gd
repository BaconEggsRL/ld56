extends Node

var num_keys = 0

func playSound(key : String):
	var player = self.get_node(key)
	if player:
		player.play()
