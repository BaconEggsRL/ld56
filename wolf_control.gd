extends Control

var player_name
var score_int : int = 0
var score_float : float = 0.0

@onready var inc_score_button = $Button
@onready var line_edit: LineEdit = $LineEdit

var focused : bool = false


func _process(_delta):
	if Input.is_action_just_released("restart"):
		if not focused:
			# print("restart")
			Global.resetGlobals()
			get_tree().reload_current_scene()
		
		

func _on_button_pressed() -> void:
	score_int += 1
	inc_score_button.text = str(score_int)

func _on_submit_button_pressed() -> void:
	score_int = Global.score_int
	score_float = Global.score_float
	
	if line_edit.text != "":
		player_name = line_edit.text
		SilentWolf.Scores.save_score(player_name, -score_float)
		get_tree().change_scene_to_file("res://addons/silent_wolf/Scores/Leaderboard.tscn")
	
		Global.resetGlobals()


func _on_line_edit_focus_entered() -> void:
	print("line focus entered")
	focused = true
	pass # Replace with function body.


func _on_line_edit_focus_exited() -> void:
	print("line focus exit")
	focused = false
	pass # Replace with function body.
