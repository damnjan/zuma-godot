extends PathFollow2D

class_name FollowingBall

var BallScene = preload("res://Ball.tscn")

var origin_position

var _is_dying = false

var frame:
	get:
		return ball.frame
	set(value):
		ball.frame = value

var ball: Ball

var _pos

func _init(frame):
	ball = BallScene.instantiate()
	if frame != null:
		ball.frame = frame
	add_child(ball)
	
func _ready():
	if origin_position:
		ball.global_position = origin_position
	
func _physics_process(delta):
	if !_is_dying:
		ball.global_position = lerp(ball.global_position, global_position, delta * 10)



	

#func add_ball(ball: Ball):
#	self.ball = ball
#	add_child(ball)
	
func kill_ball():
	_is_dying = true
	ball.die(self)
