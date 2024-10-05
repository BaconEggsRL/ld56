extends CharacterBody2D


var SPEED = 300.0
var JUMP_VELOCITY = -400.0
var FOLLOW_SPEED = 4.0
var AURA_LERP_SPEED = 4.0

@export var player : CharacterBody2D
@onready var following_player : bool = true

@onready var control_marker = $control_marker
@onready var collect_aura = $collect_aura
@onready var collect_area = $collect_area
@onready var collect_area_collision = collect_area.get_node("CollisionShape2D")

var y_offset = 10


@onready var collected : bool = false
@onready var thrown : bool = false
@onready var available : bool = false


signal friend_collected
signal friend_available

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
func solve_path(v_0: Vector2, start: Vector2 = start_point.position + Vector2(0,64)):

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
	return
	


func _on_thrown(_friend, throw_array):
	
	var vel = throw_array[0]
	var _theta = throw_array[1]
	self.THROW_VELOCITY = vel
	
	print(vel.x)
	######################################################
	var damp_speed = remap(abs(vel.x), 0, 2300, 1, 7)
	print(damp_speed)
	self.THROW_XDAMP_SPEED = damp_speed
	######################################################


	self.available = false

	new_color = COLOR_AVAILABLE
	# collect_aura.color = new_color
	collect_area_collision.call_deferred("set", "disabled", false)
	collect_aura.show()
	
	self.velocity = THROW_VELOCITY
	
	self.thrown = true
	self.following_player = false
	if self.following_player:
		self.collision_layer = 0
	else:
		self.collision_layer = 2

	

func _on_changed_control(player_controlled):
	if player_controlled:
		control_marker.hide()
	else:
		if self.available:
			control_marker.show()
		
	self.following_player = player_controlled
	if self.following_player:
		self.collision_layer = 0
	else:
		self.collision_layer = 2
		
	



func _ready() -> void:
	self.SPEED = player.SPEED
	self.JUMP_VELOCITY = player.JUMP_VELOCITY
	player.changed_control.connect(_on_changed_control)
	self.collect_aura.color = COLOR_COLLECTABLE
	# solve_path(50, deg_to_rad(30))
	friend_collected.connect(player._on_friend_collected)
	friend_available.connect(player._on_friend_available)
	control_marker.hide()
	


func _physics_process(delta: float) -> void:
	
	if lerp_color:
		self.collect_aura.color = self.collect_aura.color.lerp(new_color, delta * AURA_LERP_SPEED)
		if self.collect_aura.color == new_color:
			lerp_color = false
			collect_aura.hide()

	if collected:
	
		if not following_player:
			# Add the gravity.
			if not is_on_floor():
				velocity += get_gravity() * delta
				
			if not thrown:	

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
				
				
			else:  # thrown
				velocity.x = move_toward(velocity.x, 0, THROW_XDAMP_SPEED)
				
				if not is_on_floor():
					var temp_velocity = velocity
					move_and_slide()
					if get_slide_collision_count() > 0:
						var collision = get_slide_collision(0)
						if collision != null:
							var collider = collision.get_collider()
							if collider.is_in_group("wall"):
								temp_velocity = temp_velocity.bounce(collision.get_normal()) * THROW_BOUNCE_DAMP*1.25
								velocity = temp_velocity
							if collider.is_in_group("floor"):
								temp_velocity.y = temp_velocity.bounce(collision.get_normal()).y * THROW_BOUNCE_DAMP/1.75
								velocity.y = temp_velocity.y
					#var collision = move_and_collide(velocity * delta)
					#if collision:
						## print("COLLIDE")
						#var collider = collision.get_collider()
						## print(collider)
						#if collider.is_in_group("wall"):
							## print("wall")
							#velocity = velocity.bounce(collision.get_normal()) * THROW_BOUNCE_DAMP
						#if collider.is_in_group("floor"):
							## print("floor")
							## velocity = velocity.bounce(collision.get_normal()) * THROW_BOUNCE_DAMP
							## move_and_slide()
							#velocity = velocity.slide(collision.get_normal())
							#pass
					pass
				else:
					# print("floor2")
					move_and_slide()
					pass
			
		else:
			
			if not thrown:
			
				var player_pos = player.position
				var follow_pos = player_pos + Vector2(0, -y_offset*10)
				self.position = self.position.lerp(follow_pos, delta * FOLLOW_SPEED)
				
			else:  # thrown
				
				if not is_on_floor():
					velocity += get_gravity() * delta
					
				#var collision = move_and_collide(velocity * delta)
				#if collision:
					#print("COLLIDE")
					#velocity = velocity.bounce(collision.get_normal())
				
		


func _on_collect_area_body_entered(body: Node2D) -> void:
	# print(body.name)
	if body.is_in_group("player"):
		if self.collected == false:
			collect_area_collision.call_deferred("set", "disabled", true)
			# $Sound.play()
			collect_area.hide()
			# friend_collected.connect(player._on_friend_collected)
			friend_collected.emit(self)
			self.collected = true
			self.available = true
			
			# print_debug(self.collect_aura.color)
			new_color = COLOR_TRANSPARENT
			lerp_color = true
			# collect_aura.hide()
			
		elif self.available == false:
			collect_area_collision.call_deferred("set", "disabled", true)
			# $Sound.play()
			collect_area.hide()
			# friend_available.connect(player._on_friend_available)
			friend_available.emit(self)
			self.available = true
			
			# print_debug(self.collect_aura.color)
			new_color = COLOR_TRANSPARENT
			lerp_color = true
			# collect_aura.hide()
