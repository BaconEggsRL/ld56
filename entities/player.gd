extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var player_controlled = true
signal changed_control
signal thrown


@onready var num_friends_collected = 0
@onready var friends_available : Array[CharacterBody2D] = []
# first friend is out by default. (element 0)
# friends are appended to the end of the array as they come in. (last element)
# and exit from the front of the array as they leave (element 0).

@onready var charging_throw : bool = false

@export var num_friends_collected_label : Label
@export var num_friends_available_label : Label


func _on_friend_collected(friend) -> void:
	# print_debug("collected")
	# print_debug(friend)
	num_friends_collected += 1
	friends_available.append(friend)
	# print_debug(friends_available)
	
	# num friends collected
	var collected_string = "%s / 10" % str(num_friends_collected)
	self.num_friends_collected_label.text = collected_string
	
	# num friends available
	var available_string = "%s / %s" % [str(friends_available.size()), str(num_friends_collected)]
	self.num_friends_available_label.text = available_string
	
	

func _on_friend_available(friend) -> void:
	# print_debug("collected")
	# print_debug(friend)
	friends_available.append(friend)
	
	#print(friend.lerp_color)
	#print(friend.collected)
	#print(friend.following_player)
	#print(friend.thrown)
	
	friend.following_player = true
	friend.thrown = false
	# print_debug(friends_available)
	
	# num friends available
	var available_string = "%s / %s" % [str(friends_available.size()), str(num_friends_collected)]
	self.num_friends_available_label.text = available_string



func _ready() -> void:
	self.num_friends_collected_label.text = "0 / 10"


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
					var friend = friends_available[0]
					var traj = friend.get_node("Line2D")
					traj.hide()
					
					thrown.connect(friend._on_thrown)
					thrown.emit(friend)
					thrown.disconnect(friend._on_thrown)
					
					# num friends available
					friends_available.remove_at(0)
					var available_string = "%s / %s" % [str(friends_available.size()), str(num_friends_collected)]
					self.num_friends_available_label.text = available_string
	
	
				else:  
					print("do nothing")
					
			else:
				
				var friend = friends_available[0]
				var traj = friend.get_node("Line2D")
				
				if Input.is_action_pressed("charge_throw"):
					
					
					friend.draw_trajectory()
					
					charging_throw = true
					traj.show()
				else:
					traj.hide()

					
					
			
	
	
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
