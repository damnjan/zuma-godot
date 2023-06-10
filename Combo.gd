extends Node2D

var value: int = 2

@onready var label: Label = $Label

func _ready():
	play()


func play():
	var duration = 1 + (value - 2) * 0.2
	var red = min(value * 0.4, 1)
	var green = min(1.25/value, 1)
	var colors = {
		2: Color.GREEN_YELLOW,
		3: Color.ORANGE,
		4: Color.ORANGE_RED,
		5: Color.RED,
	}
	var color = colors[value] if colors.has(value) else colors[5]
	label.label_settings.font_color = color
	label.text = "COMBO x" + str(value)
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE * 0.25
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, 'scale', (0.5 + (value - 2) * 0.5)  * Vector2.ONE, duration)
	tween.tween_property(label, 'modulate', Color(1,1,1,0), duration)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
