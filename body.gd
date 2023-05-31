extends Area2D

signal died(index)

var frame = randi_range(0,3)
var follow_to_remove

func _ready():
	$Sprite.frame = frame
	
func die(follow):
	follow_to_remove = follow
	$AnimationPlayer.play("die")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "die":
		died.emit(follow_to_remove)
