extends Node2D

class_name ShootingBall

signal collided(ball: Ball, area: Area2D, normal: Vector2)

enum State {
	IDLE, SHOOTING
}

var state = State.IDLE

@onready var ball: Ball = $Ball

var _direction: Vector2
var _velocity: Vector2

func _physics_process(delta):
	if state == State.SHOOTING:
		position += _direction * Globals.SHOOTING_SPEED
		
	if position.distance_to(Vector2.ZERO) > 10000:
		print("Removing shooting ball")
		queue_free()

func shoot(direction: Vector2):
	_direction = direction
	state = State.SHOOTING
	ball.area_entered.connect(_on_ball_area_entered)
	
func change_color():
	ball.frame += 1
	if ball.frame == Globals.NUMBER_OF_COLORS:
		ball.frame = 0


func _on_ball_area_entered(area):
	var normal = (ball.global_position - area.global_position).normalized().rotated(-area.get_global_transform().get_rotation())
	Events.shooting_ball_collided.emit(ball, area, normal)
	collided.emit(ball, area, normal)	
	ball.area_entered.disconnect(_on_ball_area_entered)
	queue_free()
	
