extends CanvasLayer

const LERP_SPEED = 4.0

@onready var fade_bg = $bg
@onready var game_over = false


@onready var bg_hidden_color = Color(1,1,1,0)
@onready var bg_color = Color(1,1,1,1)

@onready var label_hidden_color = Color(0,0,0,0)
@onready var label_color = Color(0,0,0,1)

@onready var labels = get_tree().get_nodes_in_group("win_label")


func _process(_delta):
	if Input.is_action_just_released("restart"):
		# print("restart")
		get_tree().reload_current_scene()



func _ready() -> void:
	self.hide()
	# set hidden colors
	fade_bg.color = bg_hidden_color
	for label in labels:
		var temp_settings = LabelSettings.new()
		temp_settings.font_color = label_hidden_color
		temp_settings.font_size = label.label_settings.font_size
		label.label_settings = temp_settings
	

func _on_player_game_over() -> void:
	print("GAMEOVER menu")
	self.game_over = true


func _physics_process(delta: float) -> void:
	if game_over:
		
		self.show()
		
		# lerp colors and check when over
		fade_bg.color = fade_bg.color.lerp(bg_color, delta * LERP_SPEED)
		
		for label in labels:
			label.label_settings.font_color = label.label_settings.font_color.lerp(label_color, delta * LERP_SPEED/2)

			if fade_bg.color.is_equal_approx(bg_color) or label.label_settings.font_color.is_equal_approx(label_color):
				print("DONE")
				# get_tree().paused = true
				set_physics_process(false)
				break
