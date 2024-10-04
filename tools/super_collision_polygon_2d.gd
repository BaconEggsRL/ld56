@tool
class_name SuperCollisionPolygon2D
extends CollisionPolygon2D

signal poly_changed
var last_poly : PackedVector2Array
	
		
# Number of sides for the polygon
@export var sides: int = 3:
	set(new_setting):
		sides = max(3, new_setting)  # Ensure at least 3 sides
		on_setting_update(false)
	get:
		return sides

# Radius of the polygon
@export var radius: float = 100.0:
	set(new_setting):
		radius = max(0.0, new_setting)  # Ensure positive radius
		on_setting_update(false)
	get:
		return radius


	
	
func polar_to_cartesian(r: float, theta: float) -> Vector2:
	var x: float = r * cos(theta)
	var y: float = r * sin(theta)
	return Vector2(x, y)

func createPoly(n: int) -> PackedVector2Array:
	var points: Array = []
	for i in range(n):
		
		var theta: float = PI * 2 / n * i  # get the angle for the current iteration, in radians
		var point: Vector2 = polar_to_cartesian(radius, theta)
		points.append(point)
	return points

func on_setting_update(from_editor) -> void:
	if not from_editor:
		self.polygon = createPoly(sides)
	last_poly = self.polygon
	
	# add child polygon
	var child_node = get_poly_child()
	child_node.polygon = self.polygon
	# The line below is required to make the node visible in the Scene tree dock
	# and persist changes made by the tool script to the saved scene file.
	if get_tree():
		child_node.owner = get_tree().edited_scene_root
		child_node.name = "Polygon2D"


# add child if not exist, otherwise return child
func get_poly_child() -> Polygon2D:
	for child in self.get_children():
		if child is Polygon2D:
			return child
	var child_node = Polygon2D.new()
	self.add_child((child_node))
	return child_node
	
	
# Called when the node enters the scene tree for the first time
func _ready() -> void:
	if Engine.is_editor_hint():
		poly_changed.connect(_on_poly_changed)
	on_setting_update(false)

	
func _process(_delta):
	if Engine.is_editor_hint():
		if self.polygon != last_poly:
			poly_changed.emit()


func _on_poly_changed():
	on_setting_update(true)
