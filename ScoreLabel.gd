extends Label

var initial_position: Vector2
var value: int = 0
var display_value = 0

func set_value(_value):
	value = _value
	position = initial_position
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 40), 0.1)
	tween.tween_property(self, "position", position, 0.1)
	
#	tween.tween_callback(func(): text = str(value))


# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = position
	text = "0"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if value != ceil(display_value):
		display_value = lerpf(display_value, value, delta * 3)
		text = str(ceil(display_value))
