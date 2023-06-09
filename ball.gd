extends Area2D

class_name Ball

signal exploded()

@onready var collision_shape = $CollisionShape2D

var frame

func set_random_color():
	frame = randi_range(0,3)
	
func _init():
	set_random_color()

func _ready():
	$Sprite.frame = frame
	
func _process(delta):
	$Sprite.frame = frame
	
func explode():
	self.set_collision_layer_value(1, false)
	$AnimationPlayer.play("explode")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		exploded.emit()
		$AnimationPlayer.play("RESET")
		modulate = Color(1,1,1,0.3)
		
#		queue_free()
