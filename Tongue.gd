extends Node2D

signal returned
signal collided(ball: Ball)

enum State { SHOOTING, RETURNING, IDLE }

var state = State.IDLE

@onready var sprite = $BallSprite

var velocity := Vector2.ZERO

var frame = null
var origin

func _ready():
	sprite.hide()

func shoot():
	if state != State.IDLE:
		return
	frame = null
	sprite.hide()
	velocity.y = -Globals.TONGUE_SPEED
	state = State.SHOOTING

	

func _physics_process(delta):

	if position.y < -1500:
		state = State.RETURNING
	elif position.y > 0:
		returned.emit()
		state = State.IDLE
		
	match state:
		State.SHOOTING:
			velocity.y = -Globals.TONGUE_SPEED
			Globals.check_collision_with_follows(self, 0, _on_follow_collision)
		State.RETURNING:
			velocity.y = Globals.TONGUE_SPEED
		State.IDLE:
			velocity = Vector2.ZERO
			position = Vector2.ZERO
			
	position += velocity * delta
	

func _on_follow_collision(ball: FollowingBall):
	collided.emit(ball)
	sprite.position = to_local(ball.global_position)
	var tween = create_tween()
	tween.tween_property(sprite, 'position', Vector2.ZERO, 0.1)
	frame = ball.frame
	sprite.frame = ball.frame
	sprite.show()
	velocity.y = Globals.TONGUE_SPEED
	state = State.RETURNING
