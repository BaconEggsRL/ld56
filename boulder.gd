extends RigidBody2D

@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var camera : Camera2D = get_tree().get_first_node_in_group("camera")

@onready var spawn_position : Vector2 = self.position

@onready var dying = false

var min_x
var max_x




func _ready() -> void:
	await camera.ready
	min_x = camera.prev_x - 100
	max_x = camera.next_x + 100
	
	
func _on_death() -> void:
	
	# set dying
	dying = true
	self.freeze = true

	# play death sound
	Global.playSound("explode")
	
	# spawn new and kill self
	Global.makeBoulder(spawn_position, min_x, max_x)
	self.queue_free()
	


func _process(_delta: float) -> void:
	
	
	if not dying:

		if self.position.y > player.death_y:
			self._on_death()
			return
			
		#if min_x:
			#if self.position.x < min_x:
				#self._on_death()
				#return
		#if max_x:
			#if self.position.x > max_x:
				#self._on_death()
				#return
