extends Path2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	draw_polyline(curve.get_baked_points(), Color.from_string('#21220f', Color.BLUE), 20, true)
