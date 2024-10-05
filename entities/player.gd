extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var player_controlled = true
signal changed_control


@onready var num_friends_collected = 0
@onready var friends_available : Array[CharacterBody2D] = []

@onready var charging_throw : bool = false


func _on_friend_collected(friend) -> void:
	# print_debug("collected")
	# print_debug(friend)
	num_friends_collected += 1
	friends_available.append(friend)
	# print_debug(friends_available)



func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:

	
	# Check if changing input
	if friends_available.size() > 0:
		if Input.is_action_just_pressed("change_control"): # and is_on_floor():
			player_controlled = not player_controlled
			changed_control.emit(player_controlled)
	
	
	# Check if charging throw
	if player_controlled:
		if Input.is_action_just_pressed("throw"):
			if Input.is_action_pressed("charge_throw"):
				print("throw")
			else:  
				print("do nothing")
		else:
			if Input.is_action_pressed("charge_throw"):
				charging_throw = true
			
	
	
	if player_controlled:
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
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		
	move_and_slide()
