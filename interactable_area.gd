extends Area2D

signal interaction

# this signal gets connected by bodies interacting with
func _on_interacted_with(body: Node2D):
	interaction.emit(body) 
