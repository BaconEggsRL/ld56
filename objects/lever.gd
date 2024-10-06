extends Node2D

@export var interactable : InteractableComponent
@onready var lever_arm = $lever_arm

@export var toggled_body : StaticBody2D
@onready var is_toggled := false

@onready var move_lever_sound := $move_lever

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.interaction.connect(_on_interacted_with)
	_on_lever_changed()


func _on_lever_changed() -> void:
	if is_toggled:
		toggled_body.show()
		toggled_body.set_collision_layer_value(1, true)
		toggled_body.set_collision_layer_value(2, true)
		toggled_body.set_collision_layer_value(3, true)
	else:
		toggled_body.hide()
		toggled_body.set_collision_layer_value(1, false)
		toggled_body.set_collision_layer_value(2, false)
		toggled_body.set_collision_layer_value(3, false)
	
	print("LEVER MOVED: ", is_toggled)
		
		
# this signal gets connected by bodies interacting with
func _on_interacted_with(_body: Node2D):
	print("move lever")
	move_lever_sound.play()
	lever_arm.rotation = -lever_arm.rotation
	self.is_toggled = lever_arm.rotation < 0
	_on_lever_changed()
