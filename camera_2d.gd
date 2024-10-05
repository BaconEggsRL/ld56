extends Camera2D

signal changed_level

@export var player: CharacterBody2D
@onready var player_x : float = get_player_x()
@onready var player_size_offset : float = 16.0

@onready var size = get_viewport().size
@onready var dx = size.x

@onready var next_x = dx
@onready var prev_x = 0
@onready var level : int = 0

# show or hide debug print statements
var debugging = false


func debug():
	if debugging:
		print("level = ", self.level)
		print("cam_x = ", self.global_position.x)
		print("player_x = ", player_x)
		print("next_x = ", next_x)
		print("prev_x = ", prev_x)
	
	
func get_player_x():
	return player.global_position.x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	player_x = get_player_x()
	
	# camera must move twice as far as the player has traveled.
	# up direction is -y
	if player_x > next_x + player_size_offset:
		
		# if player has moved by h
		self.global_position.x += dx
		next_x += dx
		prev_x += dx
		level += 1
		changed_level.emit()
		debug()
	
	if player_x < prev_x - player_size_offset:
		self.global_position.x -= dx
		next_x -= dx
		prev_x -= dx
		level -= 1
		changed_level.emit()
		debug()
