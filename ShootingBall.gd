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
		Globals.for_each_visible_ball(func(ball):
			var distance = ball.global_position.distance_to(global_position)
			if distance <= Globals.BALL_WIDTH:
				_on_ball_area_entered(ball)
				set_physics_process(false)
				return true
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


func _on_ball_area_entered(area):
	var normal = (ball.global_position - area.global_position).normalized().rotated(-area.get_global_transform().get_rotation())
	Events.shooting_ball_collided.emit(ball, area, normal)
	collided.emit(ball, area, normal)	
	queue_free()
	
