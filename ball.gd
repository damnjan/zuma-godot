## Balls don't have a collision mask becaue they don't need it and it is a HUGE performance impact

extends Area2D

class_name Ball

signal exploded()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite

var ExplosionScene = preload("res://explosion.tscn")

var _frame
var frame:
	set(value):
		_frame = value
		_update_sprite_frame()
	get:
		return _frame

func set_random_color():
	frame = randi_range(0, Globals.NUMBER_OF_COLORS - 1)
	
func _init():
	set_random_color()
	
func _ready():
	scale = Globals.BALL_WIDTH / Globals.ORIGINAL_BALL_WIDTH * Vector2.ONE
	_update_sprite_frame()

func _update_sprite_frame():
	if sprite:
		assert(Globals.NUMBER_OF_COLORS <= sprite.sprite_frames.get_frame_count("default"), "Number of colors exceedes number of frames")	
		sprite.frame = frame
	
	

	
func explode():
	var explosion = ExplosionScene.instantiate()
	add_child(explosion)
	var color_particles = explosion.get_node("ColorParticles")
	var white_particles = explosion.get_node('WhiteParticles')
	white_particles.one_shot = true	
	color_particles.one_shot = true	
	color_particles.emitting = true
	white_particles.emitting = true	
	var color1: Color = Globals.color_dict[frame] if Globals.color_dict[frame] else Color.WHITE
	var color2 = color1
	color1.a = 1
	color2.a = 0
	color_particles.texture.gradient.set_color(0, color1)
	color_particles.texture.gradient.set_color(1, color2)	
#	self.set_collision_layer_value(1, false) 
	sprite.queue_free()
	collision_shape.queue_free()
	
	await get_tree().create_timer(1).timeout
	exploded.emit()


#func _on_animation_player_animation_finished(anim_name):
#	if anim_name == "explode":
#		exploded.emit()
#		$AnimationPlayer.play("RESET")
#		modulate = Color(1,1,1,0.3)
