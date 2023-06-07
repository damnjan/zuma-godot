extends PathFollow2D

class_name FollowingBall

var BallScene = preload("res://Ball.tscn")

var origin_position

# TODO:
# refactor what is private and what is public
# maybe change is_dying and is_ready to states
# is_ready refers to is it ready to be tested for matching - becomes ready after a certain delay when shot into a chain

var _is_dying = false

var is_ready = false

# in rare cases when a ball is merged to another group but didn't have time to check itself
var scheduled_for_check = false

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
	ball.died.connect(_on_ball_died)
	
func _ready():
	if origin_position:
		ball.global_position = origin_position
	
func _physics_process(delta):
	if !_is_dying:
		ball.global_position = lerp(ball.global_position, global_position, delta * 10)



func _on_ball_died():
#	print("Ball ded")
#	queue_free()
	pass

#func add_ball(ball: Ball):
#	self.ball = ball
#	add_child(ball)
	
func kill_ball():
	_is_dying = true
	ball.die()
