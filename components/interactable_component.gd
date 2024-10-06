@tool
class_name InteractableComponent
extends Area2D

signal interaction
var colliders = []
@export var groups : Array[String] = ["friend", "player"]

# Radius of the collision area
@export var radius: float = 100.0:
	set(new_setting):
		radius = max(0.0, new_setting)  # Ensure positive radius
		on_setting_update()
	get:
		return radius



func on_setting_update() -> void:
	var rect = RectangleShape2D.new()
	rect.extents = Vector2(radius, radius)
	$CollisionShape2D.shape = rect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	on_setting_update()


# this signal gets connected by bodies interacting with
func _on_interacted_with(body: Node2D):
	interaction.emit(body) 


func _on_body_entered(body: Node2D):
	# print(body)
	colliders.append(body)
	# print(colliders)
	for group in groups:
		if body.is_in_group(group):
			body.interactables.append(self)
			# print("interactables added = ", body.interactables)
	
	
func _on_body_exited(body: Node2D):
	# print(body)
	colliders.erase(body)
	# print(colliders)
	for group in groups:
		if body.is_in_group(group):
			body.interactables.erase(self)
			# print("interactables erased = ", body.interactables)
