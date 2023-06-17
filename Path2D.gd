extends Path2D

func _draw():
	draw_polyline(curve.get_baked_points(), Color.from_string('#21220f', Color.BLUE), 20, true)
