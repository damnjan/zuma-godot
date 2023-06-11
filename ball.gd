extends Area2D

class_name Ball

signal exploded()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var color_particles = $ColorParticles
@onready var white_particles = $WhiteParticles

var frame

func set_random_color():
	frame = randi_range(0, Globals.NUMBER_OF_COLORS - 1)
	
func _init():
	set_random_color()
	
func _ready():
	scale = Globals.BALL_WIDTH / Globals.ORIGINAL_BALL_WIDTH * Vector2.ONE
	color_particles.emitting = false
	color_particles.one_shot = true
	white_particles.emitting = false	
	white_particles.one_shot = true
	
	
	
	
func _process(delta):
	assert(Globals.NUMBER_OF_COLORS <= sprite.sprite_frames.get_frame_count("default"), "Number of colors exceedes number of frames")	
	sprite.frame = frame
	
func explode():
	var color1: Color = Globals.color_dict[frame] if Globals.color_dict[frame] else Color.WHITE
	var color2 = color1
	color1.a = 1
	color2.a = 0
	color_particles.texture.gradient.set_color(0, color1)
	color_particles.texture.gradient.set_color(1, color2)	
	self.set_collision_layer_value(1, false) # is this needed since animation player disables collision shape?
	$AnimationPlayer.play("explode")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		exploded.emit()
		$AnimationPlayer.play("RESET")
		modulate = Color(1,1,1,0.3)
