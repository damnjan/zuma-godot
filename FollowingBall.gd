extends PathFollow2D

class_name FollowingBall

var BallScene = preload("res://Ball.tscn")

var frame:
	get:
		return ball.frame
	set(value):
		ball.frame = value

var ball: Ball

func _init(frame):
	ball = BallScene.instantiate()
	if frame != null:
		ball.frame = frame
	add_child(ball)



	

#func add_ball(ball: Ball):
#	self.ball = ball
#	add_child(ball)
	
func kill_ball():
	ball.die(self)
