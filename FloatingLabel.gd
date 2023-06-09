extends Label

var tween: Tween

var initial_pos
var prev_value = 0

func _ready():
	initial_pos = position
	text = ""
	tween = create_tween()
	tween.stop()
	
func set_value(value):
	text = "" if value == 0 else "+" + str(value)
	
	
	if not tween.is_running() and value > prev_value:
		tween = create_tween()
		tween.tween_property(self, "position", initial_pos - Vector2(0,20), 0.1)
		tween.tween_property(self, "position", initial_pos, 0.1)
		
	prev_value = value
	
