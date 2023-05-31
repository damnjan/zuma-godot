extends PathFollow2D

class_name FollowingBall

var ball: Ball

func add_ball(ball: Ball):
	self.ball = ball
	add_child(ball)
	
func kill_ball():
	ball.die(self)
