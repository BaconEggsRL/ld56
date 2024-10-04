@tool
class_name SuperLine2D
extends Line2D


# Origin of the line
@export var x_start: int = 0:
	set(new_setting):
		x_start = new_setting
		on_setting_update()
	get:
		return x_start
		
@export var y_start: int = 0:
	set(new_setting):
		y_start = new_setting
		on_setting_update()
	get:
		return y_start
		
		
# Length of the line
@export var length: int = 50:
	set(new_setting):
		if new_setting >= 0:
			length = clamp(new_setting, 2, 500) # between 2 and 500
		else:
			length = clamp(new_setting, -500, -2) # between 2 and 500
			
		on_setting_update()
	get:
		return length
		

# Slope of the line
@export var slope: float = 1.0:
	set(new_setting):
		slope = new_setting
		on_setting_update()
	get:
		return slope
	

func drawLine() -> PackedVector2Array:
	var points_copy : PackedVector2Array = self.points
	points_copy.clear()
	
	var origin = Vector2(x_start, y_start)
	points_copy.append(origin)
	
	var delta = Vector2(1, -1 * slope)  # slope is reverse in godot
	points_copy.append((delta * length) + origin)
	
	return points_copy

func on_setting_update() -> void:
	self.points = drawLine()


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	on_setting_update()
