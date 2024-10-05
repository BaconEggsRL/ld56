extends CharacterBody2D


const SPEED = 350.0
const JUMP_VELOCITY = -400.0
var THROW_POWER := Vector2(2.0, 2.0)
# var MAX_THROW_VELOCITY := Vector2(500, 500)

@onready var in_control = true
@onready var control_marker = $control_marker

signal request_return
signal changed_control
signal friend_thrown


@onready var control_number := -1

@onready var num_friends_collected = 0
@onready var num_friends_returned = 0
@onready var friends_collected : Array[CharacterBody2D] = []
@onready var friends_thrown : Array[CharacterBody2D] = []
# first friend is out by default. (element 0)
# friends are appended to the end of the array as they come in. (last element)
# and exit from the front of the array as they leave (element 0).

@export var num_friends_collected_label : Label
@export var num_friends_returned_label : Label

@onready var trajectory = self.get_node("Line2D")
@onready var trajectory_marker = self.get_node("Marker2D")

@onready var sound : Node2D = $sound



# when friend is first collected
func _on_friend_collected(friend) -> void:
	# play sound
	sound.get_node("collect").play()
	
	# inc counts
	num_friends_collected += 1
	num_friends_returned += 1
	
	# append to array and set control number
	friends_collected.append(friend)
	friend.control_number = num_friends_collected-1
	print("(collect) control = ", friend.control_number)
	
	# num friends collected
	var collected_string = "%s / 10" % str(num_friends_collected)
	self.num_friends_collected_label.text = collected_string
	
	# num friends available
	var available_string = "%s / %s" % [str(num_friends_returned), str(num_friends_collected)]
	self.num_friends_returned_label.text = available_string
	
	

# when friend is recalled or returned
func _on_friend_returned(friend) -> void:
	
	# play sound
	sound.get_node("return").play()
	
	print("====================================")
	print("BEFORE:")
	print("friends thrown = ", friends_thrown)
	print("in_control = ", in_control)
	print("num_friends_returned = ", num_friends_returned)
	print("num_friends_collected = ", num_friends_collected)
	print("current control_number = ", self.control_number)
	print("====================================")
	
	# inc counts
	friend.returned = true;
	num_friends_returned += 1

	# num friends available to be thrown (num friends returned)
	var available_string = "%s / %s" % [str(num_friends_returned), str(num_friends_collected)]
	self.num_friends_returned_label.text = available_string
	
	# go back to player control if none left
	if not in_control:
		# all friends returned
		if num_friends_returned == num_friends_collected:
			self.change_control(-1)
		# only one friend returned--switch to other friend
		else:
			print("**************this should be triggering***********************")
			change_actor()
	
	# update thrown array (after changing actors, if needed)
	self.friends_thrown.erase(friend)
	
	# friends_thrown = []
	print("====================================")
	print("AFTER:")
	print("friends thrown = ", friends_thrown)
	print("in_control = ", in_control)
	print("num_friends_returned = ", num_friends_returned)
	print("num_friends_collected = ", num_friends_collected)
	print("current control_number = ", self.control_number)
	print("====================================")
	
	

func _on_changed_control(new_control_number: int) -> void:
	print("control to = ", new_control_number)
	self.control_number = new_control_number
	
	if new_control_number == -1:
		in_control = true
		control_marker.visible = true
	else:
		in_control = false
		control_marker.visible = false
	

# switch between 2 or more actors
func change_actor() -> void:
	
	print("changing actor")
	
	var current_control = self.control_number
	var new_control_number
	
	# if player in control, go to first thrown
	if current_control == -1:
		new_control_number = friends_thrown[0].control_number
		self.change_control(new_control_number)
		return
	
	# otherwise get next control number
	var next_index
	for i in range(friends_thrown.size()):
		var f = friends_thrown[i]
		if f.control_number == current_control:
			# print("found friend in control: ", f)
			# print("with control number: ", f.control_number)
			
			next_index = i + 1
			if next_index >= friends_thrown.size():
				next_index = 0
			new_control_number = friends_thrown[next_index].control_number
			
			# print("next index is: ", next_index)
			# print("with control number: ", new_control_number)
			changed_control.emit(new_control_number)
			break



# Switch control to thrown friends (non-returned) if they exist.
# -1 = player, 0 = collected_0, 1 = collected_1, etc...
# skip_player: if true, cycle through thrown friends, skipping player
func change_control(new_control_number := self.control_number+1) -> void:
	
	if friends_thrown.size() > 0:
		
		var current_control = self.control_number
		if current_control != -1:
			new_control_number = -1
		else:
			if friends_thrown.size() > 0:
				new_control_number = friends_thrown[0].control_number
		
		changed_control.emit(new_control_number)
		
	else:
		if not in_control:
			changed_control.emit(-1)
		


# show the trajectory
func charge_throw(charging := false) -> void:
	
	if not charging or num_friends_returned == 0:
		self.trajectory.hide()
	
	var start_pos = self.trajectory_marker.position - Vector2(0,64)
	
	if num_friends_collected > 0:
		
		if num_friends_returned > 0:
			
			if charging:
		
				# pick the first friend who is available to throw (0, 1, 2...)
				var friend
				for i in range(num_friends_collected):
					var f = friends_collected[i]
					if f.returned:
						friend = f
						break  # get first friend

				if friend:
					
					# trajectory
					var throw_array = get_throw_velocity()
					
					#########
					# these are literally random constants I made up because it wasn't working
					# local/global position or something idk
					var vx = (throw_array[0].x / THROW_POWER.x) / 10  #########
					var vy = (throw_array[0].y / THROW_POWER.y) / 4   #########
					var test_velocity = Vector2(vx, vy)
					#########
					
					self.trajectory.points = friend.solve_path(test_velocity, start_pos).points
					self.trajectory.show()
			
			else:
				self.trajectory.hide()

							
							
# attept to throw a friend
func throw() -> void:
	
	if num_friends_collected > 0:
		
		if num_friends_returned > 0:
		
			# pick the first friend who is available to throw (0, 1, 2...)
			var friend
			for i in range(num_friends_collected):
				var f = friends_collected[i]
				if f.returned:
					friend = f
					break  # get first friend

					
			if friend:
				
				# throw
				sound.get_node("throw").play()
				
				# signal throw
				friend_thrown.connect(friend._on_thrown)
				friend_thrown.emit(friend, get_throw_velocity())
				friend_thrown.disconnect(friend._on_thrown)
				
				# update thrown array
				self.friends_thrown.append(friend)
				print("friends thrown = ", friends_thrown)
				
				# inc counts
				num_friends_returned -= 1
				friend.returned = false
				
				# debug
				print("(throw) control = ", friend.control_number)

				# label
				var available_string = "%s / %s" % [str(num_friends_returned), str(num_friends_collected)]
				self.num_friends_returned_label.text = available_string


func _ready() -> void:
	self.num_friends_collected_label.text = "0 / 10"
	control_marker.visible = self.in_control


func _physics_process(delta: float) -> void:

	# Check for return
	if Input.is_action_just_pressed("return"):
		if friends_thrown.size() > 0:
			sound.get_node("return").play()
			request_return.emit()
			
	# Check if changing input
	if num_friends_collected > 0:
		if Input.is_action_just_pressed("switch_actor"): # and is_on_floor():
			if friends_thrown.size() < 2:
				self.change_control()
			else:
				self.change_actor()
		
		if Input.is_action_just_pressed("change_control"): # and is_on_floor():
			self.change_control()
	
		# if player in control
		if in_control:
			# throw
			if Input.is_action_pressed("charge_throw"):
				self.charge_throw(true)
				if Input.is_action_just_pressed("throw"):
					self.throw()
				
			if Input.is_action_just_released("charge_throw"):
				self.charge_throw(false)

	
	if in_control:
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			sound.get_node("jump").play()

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




func get_throw_velocity() -> Array:

	
	var start_pos : Vector2 = self.global_position
	var mouse_pos : Vector2 = get_global_mouse_position()
	#print(start_pos)
	#print(mouse_pos)
	
	var launch_vector : Vector2 = mouse_pos - start_pos
	var floor_vector : Vector2 = Vector2(start_pos.x, mouse_pos.x)
	var dot_product = launch_vector.dot(floor_vector)
	var expression = dot_product / (launch_vector.length() * floor_vector.length())
	
	var theta = acos(expression)
	# print(rad_to_deg(theta))
	
	# print(floor_vector.x)
	#if floor_vector.x < 50:
		#if floor_vector.x < 25:
			#THROW_POWER.x = 4.0
		#else:
			#THROW_POWER.x = 3.0
	#else:
		#THROW_POWER.x = 2.0
	
	var throw_vel = Vector2(launch_vector.x * THROW_POWER.x, launch_vector.y * THROW_POWER.y)
	# print(throw_vel)
	
	return [throw_vel, theta]
