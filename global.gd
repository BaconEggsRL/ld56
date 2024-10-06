extends Node

var num_keys : int = 0
var time_start : float = 0
var time_now : float = 0

var key_text_label : Label
var time_label : Label
var interactions : Node2D

var time_elapsed : float = 0

var gameover_layer : CanvasLayer


func round_place(num,places):
	return (round(num*pow(10,places))/pow(10,places))


func _process(_delta):
	if not gameover_layer.game_over:
		time_now = Time.get_unix_time_from_system()
		time_elapsed = time_now - time_start
		# print(time_elapsed)
	else:
		var seconds = str(round_place(time_elapsed, 2))
		var message = "%s seconds" % seconds
		time_label.text = message
		print(time_elapsed)
		self.set_process(false)
	
	
func _ready():
	time_start = Time.get_unix_time_from_system()
	
	
# call when game ends
func resetGlobals() -> void:
	print("reset")
	num_keys = 0
	time_start = Time.get_unix_time_from_system()
	time_now = time_start
	time_elapsed = 0
	self.set_process(true)
	

func playSound(key : String):
	var sound_player = self.get_node(key)
	if sound_player:
		sound_player.play()

func makeBoulder(pos: Vector2, min_x: float, max_x: float) -> void:
	var boulder_scene = preload("res://boulder.tscn").instantiate()
	boulder_scene.position = pos
	boulder_scene.min_x = min_x
	boulder_scene.max_x = max_x
	interactions.get_node("boulders").add_child(boulder_scene)
