extends Area2D

class_name Ball

signal exploded()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite

var frame

func set_random_color():
	frame = randi_range(0, Globals.NUMBER_OF_COLORS - 1)
	
func _init():
	set_random_color()
	
func _ready():
	scale = Globals.BALL_WIDTH / Globals.ORIGINAL_BALL_WIDTH * Vector2.ONE
	
func _process(delta):
	sprite.frame = frame
	if Globals.NUMBER_OF_COLORS > sprite.sprite_frames.get_frame_count("default"):
		assert(false, "Number of colors exceedes number of frames")
	
func explode():
	self.set_collision_layer_value(1, false)
	$AnimationPlayer.play("explode")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		exploded.emit()
		$AnimationPlayer.play("RESET")
		modulate = Color(1,1,1,0.3)
