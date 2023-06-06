extends Area2D

class_name Ball

signal died(index)

var frame
var follow_to_remove

func set_random_color():
	frame = randi_range(0,3)
	
func _init():
	set_random_color()

func _ready():
	$Sprite.frame = frame
	
func _process(delta):
	$Sprite.frame = frame
	
func die(follow):
	self.set_collision_layer_value(1, false)
	follow_to_remove = follow
	$AnimationPlayer.play("die")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "die":
		died.emit(follow_to_remove)
