extends Area2D

class_name Ball

signal died()

var frame

func set_random_color():
	frame = randi_range(0,3)
	
func _init():
	set_random_color()

func _ready():
	$Sprite.frame = frame
	
func _process(delta):
	$Sprite.frame = frame
	
func die():
	self.set_collision_layer_value(1, false)
	$AnimationPlayer.play("die")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "die":
		died.emit()
#		queue_free()
