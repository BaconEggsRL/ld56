extends CharacterBody2D


var SPEED = 300.0
var JUMP_VELOCITY = -400.0
var FOLLOW_SPEED = 4.0
var AURA_LERP_SPEED = 4.0

@export var player : CharacterBody2D
@onready var following_player : bool = true

@onready var collect_aura = $collect_aura
@onready var collect_area = $collect_area
@onready var collect_area_collision = collect_area.get_node("CollisionShape2D")

var y_offset = 10


@onready var collected : bool = false
signal friend_collected
var lerp_color = false
var new_color = Color(1,1,1,0)


@onready var line_node: Line2D = get_node("Line2D")
@onready var start_point: Marker2D = get_node("Marker2D")

const MAX_TIME := 20. # Sec
const TIME_STEP := 0.1 # Sec
const GRAV_ACC := 9.8 # Meters/Sec^2


# theta in radians, otherwise use deg_to_rad() before-hand
func solve_path(v_0: float, theta: float):
	var pts := PackedVector2Array([])
	var t: float = 0.
	var x: float = start_point.global_position.x
	var y: float = start_point.global_position.y

	# Godot y-axis is flipped
	var v_x: float = v_0 * cos(theta)
	var v_y: float = -v_0 * sin(theta)

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
	# solve_path(50, deg_to_rad(30))


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
		


func _on_collect_area_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.is_in_group("player"):
		collect_area_collision.call_deferred("set", "disabled", true)
		# $Sound.play()
		collect_area.hide()
		friend_collected.connect(player._on_friend_collected)
		friend_collected.emit(self)
		self.collected = true
		
		# print_debug(self.collect_aura.color)
		lerp_color = true
		# collect_aura.hide()
