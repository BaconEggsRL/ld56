extends CharacterBody2D


var SPEED = 300.0
var JUMP_VELOCITY = -400.0
var FOLLOW_SPEED = 4.0

@export var player : CharacterBody2D
@onready var following_player : bool = true

var y_offset = 10



func _on_changed_control(player_controlled):
	self.following_player = player_controlled
	if self.following_player:
		self.collision_layer = 0
	else:
		self.collision_layer = 2
		print(self.collision_layer)
		
	



func _ready() -> void:
	self.SPEED = player.SPEED
	self.JUMP_VELOCITY = player.JUMP_VELOCITY
	player.changed_control.connect(_on_changed_control)


func _physics_process(delta: float) -> void:
	
	
	if not following_player:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
	else:
		var player_pos = player.position
		var follow_pos = player_pos + Vector2(0, -y_offset*10)
		self.position = self.position.lerp(follow_pos, delta * FOLLOW_SPEED)
		
