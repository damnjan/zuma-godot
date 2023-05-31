extends PathFollow2D

class_name FollowingBall

var ball: Area2D

func add_ball(ball: Area2D):
	self.ball = ball
	add_child(ball)
