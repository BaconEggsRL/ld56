extends Node2D

@export var pushForce = 500

@export var bodyPath: NodePath = ".."

@onready var body: CharacterBody2D = get_node(bodyPath)

func _physics_process(_delta):
	if body.move_and_slide(): # true if collided
		for i in body.get_slide_collision_count():
			var col = body.get_slide_collision(i)
			if col.get_collider().is_in_group("boulder"):
				col.get_collider().apply_force(col.get_normal() * -pushForce)
