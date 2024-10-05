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

@onready var charging_throw : bool = false

@export var num_friends_collected_label : Label
@export var num_friends_returned_label : Label


# when friend is first collected
func _on_friend_collected(friend) -> void:
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
	
	# inc counts
	friend.returned = true;
	num_friends_returned += 1

	# num friends available to be thrown (num friends returned)
	var available_string = "%s / %s" % [str(num_friends_returned), str(num_friends_collected)]
	self.num_friends_returned_label.text = available_string
	
	# go back to player control if none left
	if num_friends_returned == num_friends_collected:
		if in_control == false:
			self.change_control(-1)
	else:
		if in_control == false:
			change_actor()
	
	# update thrown array (after changing actors, if needed)
	self.friends_thrown.erase(friend)
	
	# friends_thrown = []
	print("friends thrown = ", friends_thrown)
	
	

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
	
	var current_control = self.control_number
	
	print("change actor, current control = ", current_control)
	print("friends thrown = ", friends_thrown)
	
	# if player in control, go to first thrown
	if current_control == -1:
		self.change_control(friends_thrown[0].control_number)
		return
	
	# otherwise get next control number
	for f in friends_thrown:
		if f.control_number == current_control:
			print("found control")

			var next_index = f.thrown_index+1
			if next_index >= friends_thrown.size():
				next_index = 0

			var next_friend = friends_thrown[next_index]
			var new_control_number = next_friend.control_number
			
			print("new_control_number = ", new_control_number)
			# self.change_control(new_control_number)
			changed_control.emit(new_control_number)

	


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
		

	## only change control if we have friends
	#if num_friends_collected > 0:
		#
		## check input
		#if new_control_number >= num_friends_collected:
			#new_control_number = -1
		#assert(new_control_number < num_friends_collected)
		#assert(new_control_number >= -1)
		#
		#if new_control_number == -1:
			#changed_control.emit(-1)
			#return
	#
#
		## we can only change control to thrown friends (not returned.)
		## this mean number returned != number collected
		#if num_friends_returned < num_friends_collected:
#
			#var f
			#var found
			#for i in range(num_friends_collected):
				#f = friends_collected[i]
				#if not f.returned and not f.in_control:
					## Switch control to thrown friends (non-returned) if they exist.
					## emit who is in control to all friends and self
					#
					#print("new_control_number = ", f.control_number)
					#print("current control number = ", self.control_number)
			#
					#changed_control.emit(f.control_number)
					#found = f
					#break  # get first friend
			#if not found:
				#changed_control.emit(-1)
				#return


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
				
				# trajectory
				var traj = friend.get_node("Line2D")
				traj.hide()
				
				# signal throw
				friend_thrown.connect(friend._on_thrown)
				friend_thrown.emit(friend, get_throw_velocity())
				friend_thrown.disconnect(friend._on_thrown)
				
				# update thrown array
				self.friends_thrown.append(friend)
				friend.thrown_index = friends_thrown.size()-1
				print("friends thrown = ", friends_thrown)
				
				# inc counts
				num_friends_returned -= 1
				friend.returned = false
				
				# debug
				print("(throw) control = ", friend.control_number)
				print("(throw) index = ", friend.thrown_index)

				# label
				var available_string = "%s / %s" % [str(num_friends_returned), str(num_friends_collected)]
				self.num_friends_returned_label.text = available_string


func _ready() -> void:
	self.num_friends_collected_label.text = "0 / 10"
	control_marker.visible = self.in_control


func _physics_process(delta: float) -> void:

	# Check for return
	if Input.is_action_just_pressed("return"):
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
			if Input.is_action_just_pressed("throw"):
				if Input.is_action_pressed("charge_throw"):
					self.throw()
				else:  
					# do nothing if charge throw button wasn't also pressed
					pass
			
			# if not pressing throw
			else:
				
				if friends_collected.size() > 0:
					var friend = friends_collected[0]
					var traj = friend.get_node("Line2D")
					
					if friend.returned:
					
						if Input.is_action_pressed("charge_throw"):
							
							var throw_array = get_throw_velocity()
							#########
							# these are literally random constants I made up because it wasn't working
							# local/global position or something idk
							var vx = (throw_array[0].x / THROW_POWER.x) / 10  #########
							var vy = (throw_array[0].y / THROW_POWER.y) / 4   #########
							var test = Vector2(vx, vy)
							friend.solve_path(test)
							
							charging_throw = true
							traj.show()
						else:
							traj.hide()

	
	if in_control:
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
