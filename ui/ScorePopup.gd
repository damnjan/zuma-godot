extends Node2D

var value: int = 30

@onready var label: Label = $Label



func _ready():
	label.label_settings = label.label_settings.duplicate(false)	
	play()


func play():
	var color = Color.GREEN_YELLOW if value >= 50 else Color.YELLOW
			
		
	label.label_settings.font_color = color	
	label.text = "+" + str(value)
	label.modulate = Color.WHITE
	label.scale = Vector2.ONE
	
	var duration = 1 + value/100.0
	
	var new_scale = 2 + (value - 30) * 0.01
	
	duration = 0.5 if value <= 50 else min(duration, 3)
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, 'scale', Vector2.ONE * new_scale, duration)
	tween.tween_property(label, 'modulate', Color(1,1,1,0), duration)
	tween.set_parallel(false)
	tween.tween_callback(func():
		queue_free()
	)
