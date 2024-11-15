extends CharacterBody2D


var SPEED = 300.0
var JUMP_VELOCITY = -400.0
var FOLLOW_SPEED = 4.0
var AURA_LERP_SPEED = 4.0


# float animation
var float_time : float = 0
var default_pos = Vector2(0,0)

var amplitude : float = 10
var frequency : float = 1.5


# pushing
@export var pushForce : float = 100.0


# interactables
@onready var interactables : Array[Area2D] = []

# jumping
@onready var jumping = false
@onready var was_last_on_floor = false
@onready var coyote = false
@onready var jump_buffer = false
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBuffer



@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var camera : Camera2D = get_tree().get_first_node_in_group("camera")

@onready var control_marker = $control_marker
@onready var collect_aura = $collect_aura
@onready var collect_area = $collect_area
@onready var collect_area_collision = collect_area.get_node("CollisionShape2D")

@onready var collision_shape = $CollisionShape2D


var y_offset = 125
var MIN_X_BOUNCE : float = 10.0


@onready var collected : bool = false
@onready var returned : bool = true  # when returned state
@onready var thrown : bool = false
@onready var in_control : bool = false  # when friends are in control

var control_number : int
# from Return you can Throw
# after Throw you can Return or Control
# after Control you cannot return. you can only Control or Cycle (tab)


@export var auto_attach : bool

signal friend_collected
signal friend_returned

var lerp_color = false
var COLOR_TRANSPARENT = Color(1,1,1,0)
var COLOR_COLLECTABLE = Color(1,1,0,0.50)
var COLOR_AVAILABLE = Color(0,1,0,0.50)
var new_color = COLOR_COLLECTABLE


@onready var line_node: Line2D = get_node("Line2D")
@onready var start_point: Marker2D = get_node("Marker2D")

const MAX_TIME := 12. # Sec
const TIME_STEP := 0.1 # Sec
const GRAV_ACC := 9.8 # Meters/Sec^2

var THROW_XDAMP_SPEED = 6.0
var THROW_BOUNCE_DAMP = 0.4
var THROW_VELOCITY : Vector2 = Vector2(500.0, -500.0)


# theta in radians, otherwise use deg_to_rad() before-hand
func solve_path(v_0: Vector2, start: Vector2 = start_point.position + Vector2(0,64)) -> Line2D:

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
	line_node.points = pts
	return line_node
	


func _on_thrown(_friend, throw_array):
	self.returned = false
	
	var vel = throw_array[0]
	var _theta = throw_array[1]
	self.THROW_VELOCITY = vel
	
	# print(vel.x)
	######################################################
	var damp_speed = remap(abs(vel.x), 0, 2300, 1, 8)
	# print(damp_speed)
	self.THROW_XDAMP_SPEED = damp_speed
	######################################################

	new_color = COLOR_AVAILABLE
	# collect_aura.color = new_color
	collect_area_collision.call_deferred("set", "disabled", false)
	collect_aura.show()
	
	collision_shape.call_deferred("set", "disabled", false)
	
	self.velocity = THROW_VELOCITY



func _on_changed_control(new_control_number):
	
	if self.collected:
	
		# switch control
		if new_control_number != self.control_number:
			self.in_control = false
			control_marker.visible = false
			
			# fix velocity on changing control (prevent sliding)
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
			
		else:
			self.in_control = true
			control_marker.visible = true

		

func _on_request_return():
	# print("hello f")
	if self.collected:
		if not self.returned:
			# print("returning")
			_on_collect_area_body_entered(player)


func _on_death() -> void:
	# print("dead")
	# var level = player.level
	_on_request_return()
	
	
func _ready() -> void:
	
	self.default_pos = self.global_position

	self.SPEED = player.SPEED
	self.JUMP_VELOCITY = player.JUMP_VELOCITY
	self.collect_aura.color = COLOR_COLLECTABLE
	
	friend_collected.connect(player._on_friend_collected)
	friend_returned.connect(player._on_friend_returned)

	player.changed_control.connect(_on_changed_control)
	player.request_return.connect(_on_request_return)
	
	control_marker.hide()
	
	if auto_attach:
		await player.ready
		print(player)
		_on_collect_area_body_entered(player)
	






##########################################################################






func _physics_process(delta: float) -> void:
	
	if self.position.y > player.death_y:
		self._on_death()
	elif self.position.x < camera.prev_x - 100:
		self._on_death()
	elif self.position.x > camera.next_x + 100:
		self._on_death()
	
	if lerp_color:
		self.collect_aura.color = self.collect_aura.color.lerp(new_color, delta * AURA_LERP_SPEED)
		if self.collect_aura.color == new_color:
			lerp_color = false
			collect_aura.hide()


	if collected:
		
		if returned:
			
			var player_pos = player.position
			var follow_pos = player_pos + Vector2(0, -y_offset)
			self.position = self.position.lerp(follow_pos, delta * FOLLOW_SPEED)
		
		else:  # not returned
			
			if in_control:  # check if we have control
				
				# interact with objects
				if Input.is_action_just_pressed("interact") and in_control:
					for i in interactables:
						print("interacting with: ", i)
						i._on_interacted_with(self)

				
				# Add the gravity.
				if not is_on_floor():
					velocity += get_gravity() * delta
				else:
					if jumping:
						jumping = false
					else:
						if jump_buffer and not jumping:
							jump()
							jump_buffer = false
					
				# Handle jump.
				if Input.is_action_just_pressed("jump"):
					if (is_on_floor() or coyote) and not jumping:  # jump_available
						jump()
						print("jump")
					else:
						jump_buffer_time()
						print("buffer")

				# Get the input direction and handle the movement/deceleration.
				# As good practice, you should replace UI actions with custom gameplay actions.
				var direction := Input.get_axis("ui_left", "ui_right")
				if direction:
					velocity.x = direction * SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)
					
				# save last on floor
				if is_on_floor() != was_last_on_floor:
					was_last_on_floor = is_on_floor()
					# print("was_last_on_floor = ", was_last_on_floor)
					
				# move and update on floor
				# move_and_slide()
				# move and update on floor
				if self.move_and_slide(): # true if collided
					for i in self.get_slide_collision_count():
						var collision = self.get_slide_collision(i)
						var collider = collision.get_collider()
						if collider.is_in_group("boulder"):
							collider.apply_force(collision.get_normal() * -pushForce)
							break
				
				# check if different
				if was_last_on_floor and not is_on_floor() and not jumping:
					# print("coyote")
					coyote_time()
			
			
			else:  # not returned and not control (thrown)
				
				velocity.x = move_toward(velocity.x, 0, THROW_XDAMP_SPEED)
				
				if not is_on_floor():
					velocity += get_gravity() * delta
					var temp_velocity = velocity
					
					move_and_slide()
					
					if get_slide_collision_count() > 0:
						var collision = get_slide_collision(0)
						if collision != null:
							var collider = collision.get_collider()
							if collider.is_in_group("wall"):
								# print("wall")
								temp_velocity = temp_velocity.bounce(collision.get_normal()) * THROW_BOUNCE_DAMP*1.25
								if abs(temp_velocity.x) > MIN_X_BOUNCE:
									var bounce_sound = player.sound.get_node("bounce")
									# print("vx = ", temp_velocity.x)
									var volume = remap(abs(temp_velocity.x), MIN_X_BOUNCE, 1024, -20.0, 0.0)
									bounce_sound.volume_db = volume
									bounce_sound.play()
									velocity = temp_velocity
								
							if collider.is_in_group("floor"):
								temp_velocity.y = temp_velocity.bounce(collision.get_normal()).y * THROW_BOUNCE_DAMP/1.75
								velocity.y = temp_velocity.y

				else:
					move_and_slide()

	else: # not collected
		# print("not_collected")
		float_time += delta * frequency
		self.set_position(default_pos + Vector2(0, sin(float_time) * amplitude))
		


func _on_collect_area_body_entered(body: Node2D) -> void:
	# print(body.name)
	if body.is_in_group("player"):
		if self.collected == false:
			collect_area_collision.call_deferred("set", "disabled", true)
			# $Sound.play()
			collect_area.hide()

			friend_collected.emit(self)
			self.collected = true
			self.returned = true
			self.collision_shape.call_deferred("set", "disabled", true)
			
			# print_debug(self.collect_aura.color)
			new_color = COLOR_TRANSPARENT
			lerp_color = true
			# collect_aura.hide()
			
		else:
			collect_area_collision.call_deferred("set", "disabled", true)
			# $Sound.play()
			collect_area.hide()
			
			friend_returned.emit(self)
			self.returned = true
			self.collision_shape.call_deferred("set", "disabled", true)
			
			# print_debug(self.collect_aura.color)
			new_color = COLOR_TRANSPARENT
			lerp_color = true
			# collect_aura.hide()




func jump() -> void:
	velocity.y = JUMP_VELOCITY
	jumping = true
	
	var jump_sound = player.sound.get_node("jump")
	jump_sound.pitch_scale = 1.8
	jump_sound.play()
	# pitch_scale = 1.80, volume_db = -10.895

func coyote_time() -> void:
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
	print("jump_buffer = ", jump_buffer)
	
func _on_jump_buffer_timeout() -> void:
	jump_buffer = false
	print("jump_buffer = ", jump_buffer)
