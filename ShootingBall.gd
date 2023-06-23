extends Node2D

class_name ShootingBall

signal collided(ball: Ball, area: Area2D, normal: Vector2)

enum State {
	IDLE, SHOOTING
}

var state = State.IDLE

@onready var ball: Ball = $Ball

var _direction: Vector2

func _physics_process(delta):
	if state == State.SHOOTING:
		position += _direction * Globals.SHOOTING_SPEED * delta
		Globals.check_collision_with_follows(self, func(follow):
			_on_follow_collided(follow)
			set_physics_process(false)	
		)
		
		
		
	if position.distance_to(Vector2.ZERO) > 10000:
		queue_free()

func shoot(direction: Vector2):
	_direction = direction
	state = State.SHOOTING
	
func change_color():
	ball.frame += 1
	if ball.frame == Globals.NUMBER_OF_COLORS:
		ball.frame = 0


# todo: refactor. why ball.global_position instead of global_position? why pass ball when emitting?
func _on_follow_collided(follow: FollowingBall):
	var normal = (ball.global_position - follow.global_position).normalized().rotated(-follow.get_global_transform().get_rotation())
	Events.shooting_ball_collided.emit(ball, follow, normal)
	collided.emit(ball, follow, normal)	
	queue_free()
	
