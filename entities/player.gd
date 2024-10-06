extends CharacterBody2D

@onready var NUM_FRIENDS_TOTAL : int = get_tree().get_node_count_in_group("friend")

var was_last_on_floor_position : Vector2

const MAX_TIME := 12. # Sec
const TIME_STEP := 0.1 # Sec
const GRAV_ACC := 9.8 # Meters/Sec^2

const SPEED = 350.0
const JUMP_VELOCITY = -450.0
var THROW_POWER := Vector2(2.0, 2.0)
# var MAX_THROW_VELOCITY := Vector2(500, 500)

@onready var in_control = true
@onready var control_marker = $control_marker

signal request_return
signal changed_control
signal friend_thrown

signal game_over

# pushing
@export var pushForce : float = 300.0


# jumping
@onready var jumping = false

@onready var was_last_on_floor = false
@onready var coyote = false
@onready var jump_buffer = false

@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBuffer
@onready var jump_height_timer = $JumpHeight

@onready var can_jump_higher = false

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

@export var camera : Camera2D
@onready var death_y : float = camera.size.y + 128.0
@export var respawn : Node2D


# interactables
@onready var interactables : Array[Area2D] = []

@onready var handle_input := true


func gameover() -> void:
	print("GAMEOVER")
	self.handle_input = false
	game_over.emit()
	
	
	
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
	var collected_string = "%s / %s" % [str(num_friends_collected), str(NUM_FRIENDS_TOTAL)]
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
	
	var start_pos = self.trajectory_marker.position - Vector2(0,128)
	
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
					var vx = (throw_array[0].x / THROW_POWER.x) / 6  #########
					var vy = (throw_array[0].y / THROW_POWER.y) / 5   #########
					var test_velocity = Vector2(vx, vy)
					#########
					# var test_velocity = throw_array[0]
					self.trajectory.points = self.solve_path(test_velocity, start_pos).points
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
	RenderingServer.set_default_clear_color(Color(1,1,1,1))
	
	# Define a format string with placeholder '%s'
	var format_string ="0 / %s"
	var actual_string = format_string % str(NUM_FRIENDS_TOTAL)
	self.num_friends_collected_label.text = actual_string
	
	control_marker.visible = self.in_control
	_on_death(false)


	
func _on_death(play_sound := true) -> void:
	var boulders = get_tree().get_nodes_in_group("boulder")
	for boulder in boulders:
		boulder._on_death(false)
	
	if play_sound:
		self.sound.get_node("dead").play()
	
	var level = self.camera.level
	var node_str = "level_%s" % str(level)
	# print(node_str)
	
	
	var respawn_pt = self.respawn.get_node(node_str).position
	# var respawn_pt = self.was_last_on_floor_position
	print(respawn_pt)
	
	self.position = respawn_pt
	self.velocity = Vector2(0,0)
	
	# sound.get_node("return").play()
	request_return.emit()







##############################################################









# physics
func _physics_process(delta: float) -> void:
	
	# check if game over
	if num_friends_collected == NUM_FRIENDS_TOTAL:
		if num_friends_collected == num_friends_returned:
			gameover()
			set_physics_process(false)
			return
	
	if self.position.y > self.death_y:
		self._on_death()

	# Check for return
	if Input.is_action_just_pressed("return") and handle_input:
		if friends_thrown.size() > 0:
			sound.get_node("return").play()
			request_return.emit()
			
	# Check if changing input
	if num_friends_collected > 0:
		if Input.is_action_just_pressed("switch_actor") and handle_input:
			if friends_thrown.size() < 2:
				self.change_control()
			else:
				self.change_actor()
		
		if Input.is_action_just_pressed("change_control") and handle_input:
			self.change_control()
	
		# if player in control
		if in_control:
			# throw
			if Input.is_action_pressed("charge_throw") and handle_input:
				self.charge_throw(true)
				if Input.is_action_just_pressed("throw"):
					self.throw()
				
			if Input.is_action_just_released("charge_throw") and handle_input:
				self.charge_throw(false)

	
	if in_control:
		
		if Input.is_action_just_pressed("interact") and handle_input:
			for i in interactables:
				print("interacting with: ", i)
				i._on_interacted_with(self)
		
		# Handle jump.
		#############################################################
		
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			if jumping:
				jumping = false
			else:
				if jump_buffer and not jumping:
					jump()
					print("jump_from_jump_buffer (JUMP BUFFER)")
					jump_buffer = false
							
							
		
		
		if Input.is_action_pressed("jump") and handle_input:
			if Input.is_action_just_pressed("jump") and handle_input:
				if (is_on_floor() or coyote) and jumping == false:  # jump_available
					if is_on_floor():
						jump()
						print("jump_from_action_just_pressed (REGULAR)")
					else:
						jump()
						print("jump_from_action_just_pressed (COYOTE)")
				else:
					jump_buffer_time()
				
			#else:
				#if (is_on_floor() or coyote) and jumping == true:
					#if can_jump_higher:
						#velocity.y = JUMP_VELOCITY
			
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction
		if handle_input:
			direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
			
	else: # if not in control
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)

	
	#############################################################

	
	
	
	# save last on floor
	if is_on_floor() != was_last_on_floor:
		was_last_on_floor = is_on_floor()
		was_last_on_floor_position = self.position
		
	# move and update on floor
	if self.move_and_slide(): # true if collided
		for i in self.get_slide_collision_count():
			var collision = self.get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("boulder"):
				collider.apply_force(collision.get_normal() * -pushForce)
				break
	# move_and_slide()
	
	# check if different
	if was_last_on_floor and not is_on_floor():
		# print("coyote")
		coyote_time()





	
	
func jump() -> void:
	jumping = true
	can_jump_higher = true
	jump_height_timer.start()
	velocity.y = JUMP_VELOCITY
	
	var jump_sound = sound.get_node("jump")
	jump_sound.pitch_scale = 0.7
	jump_sound.play()
	# pitch_scale = 0.77, volume_db = -10.895

func _on_jump_height_timeout() -> void:
	can_jump_higher = false
	
func coyote_time() -> void:
	# print("coyote")
	# Delay for a set amount of time to still jump in air
	coyote = true
	coyote_timer.start()

func _on_coyote_timer_timeout() -> void:
	coyote = false
	# print("coyote = ", coyote)

func jump_buffer_time() -> void:
	# Allow player to queue jumps while mid-air
	jump_buffer = true
	jump_buffer_timer.start()
	# print("jump_buffer = ", jump_buffer)
	
func _on_jump_buffer_timeout() -> void:
	jump_buffer = false
	# print("jump_buffer = ", jump_buffer)





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


# theta in radians, otherwise use deg_to_rad() before-hand
func solve_path(v_0: Vector2, start: Vector2 = trajectory_marker.position + Vector2(0,64)) -> Line2D:
	
	# print("v_0 = ", v_0)
	# print("start = ", start)

	var pts := PackedVector2Array([])
	var t: float = 0.
	var x: float = start.x
	var y: float = start.y

	# Godot y-axis is flipped
	# var v_x: float = v_0 * cos(theta)
	# var v_y: float = -v_0 * sin(theta)
	var v_x: float = v_0.x
	var v_y: float = v_0.y

	# Very crude algorithm, specifically this is the "Euler method"
	# For more sophesticated situations (ie > 1 projectile interacting with each other)
	# use "Runge-Kutta Methods" or "Verlet Integration Methods"
	while t < MAX_TIME: # No infinities
		v_y += GRAV_ACC * TIME_STEP
		v_x += 0 # No X Forces (no drag)
		t += TIME_STEP
		x += v_x * TIME_STEP
		y += v_y * TIME_STEP
		pts.push_back(Vector2(x, y))
		if y > 400: # hit the ground
			break
	self.trajectory.points = pts
	return self.trajectory
	
