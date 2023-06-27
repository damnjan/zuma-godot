extends Label

var tween: Tween
	
func set_value(value):
	text = "" if value == 0 else "← " + str(value)
	
	
