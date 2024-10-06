extends Node2D

@onready var pickup_area : Area2D = $Area2D
@onready var groups : Array[String] = ["player", "friend"]

# @export var key_text_label : Label

# signal key_pickup


func _on_area_2d_body_entered(body: Node2D) -> void:

	for group in groups:
		
		if body.is_in_group(group):
			
			print("pickup key")
			Global.playSound("key")
			Global.num_keys += 1
			
			Global.key_text_label.text = "%s keys" % str(Global.num_keys)
			
			self.queue_free()
			
			break
