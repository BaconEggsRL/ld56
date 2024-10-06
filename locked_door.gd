extends StaticBody2D

var colliders = []

@export var groups : Array[String] = ["friend", "player"]
@export var interaction_area : Area2D

var invalid_font_color = Color(1,0,0,1)
var base_label_settings : LabelSettings
@onready var label_color_timer : Timer = $label_color_timer


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	


func unlock_door() -> void:
	print("unlock door")

	Global.playSound("door")
	Global.num_keys -= 1
	
	Global.key_text_label.text = "%s keys" % str(Global.num_keys)
	
	self.queue_free()

	
	
# this signal gets called when the interactable area is interacted with
func _on_interactable_area_interaction(_body: Node2D) -> void:
	print("INTERACT with: ", _body)
	print("try to unlock door")
	if Global.num_keys > 0:
		unlock_door()
	else:
		
		if label_color_timer.is_stopped():
			Global.playSound("invalid")
			self.base_label_settings = Global.key_text_label.label_settings
			var temp_settings = LabelSettings.new()
			temp_settings.font_color = invalid_font_color
			temp_settings.font_size = base_label_settings.font_size
			Global.key_text_label.label_settings = temp_settings
			label_color_timer.start()


func _on_label_color_timer_timeout() -> void:
	Global.key_text_label.label_settings = base_label_settings
	
	
func _on_body_entered(body: Node2D) -> void:
	print(body)
	colliders.append(body)
	print(colliders)
	for group in groups:
		if body.is_in_group(group):
			body.interactables.append(interaction_area)
			# print("interactables added = ", body.interactables)
	
	
func _on_body_exited(body: Node2D) -> void:
	print(body)
	colliders.erase(body)
	print(colliders)
	for group in groups:
		if body.is_in_group(group):
			body.interactables.erase(interaction_area)
			# print("interactables erased = ", body.interactables)
