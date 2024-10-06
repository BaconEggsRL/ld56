extends Node

var num_keys : int = 0
var time_start : float = 0
var time_now : float = 0

var time_elapsed : float = 0
var score_int : int = 0
var score_float : float = 0.0
var score_str : String



var key_text_label : Label
var time_label : Label
var interactions : Node2D
var gameover_layer : CanvasLayer


func round_place(num,places):
	return (round(num*pow(10,places))/pow(10,places))


func _process(_delta):
	if gameover_layer:
		if not gameover_layer.game_over:
			time_now = Time.get_unix_time_from_system()
			time_elapsed = time_now - time_start
			# print(time_elapsed)
		else:  # game is over
			
			score_int = int(round_place(time_elapsed, 4) * 1000)  # ms
			score_float = float(round_place(time_elapsed, 4))  # seconds
			score_str = str(score_float)
			var message = "%s seconds" % score_float
			time_label.text = message
			
			print(score_str)
			var wolf_control = gameover_layer.get_node("wolf_control")
			print(wolf_control)

			
			self.set_process(false)
	
	
func _ready():
	time_start = Time.get_unix_time_from_system()
	score_int = 0
	score_float = 0
	
	SilentWolf.configure({
		"api_key": "lMO7cGJjrjan6AqwY0F6c90fX7XMJALK4Kz4ZUkk",
		"game_id": "tinyfriends",
		"log_level": 1
	})

	SilentWolf.configure_scores({
		"open_scene_on_close": "res://game.tscn"
	})



# call when game ends
func resetGlobals() -> void:
	print("reset")
	num_keys = 0
	time_start = Time.get_unix_time_from_system()
	time_now = time_start
	time_elapsed = 0
	score_int = 0
	score_float = 0
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
