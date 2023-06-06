extends Node2D

class_name ShootingBall

signal collided(ball: Ball, area: Area2D, normal: Vector2)

enum State {
	IDLE, SHOOTING
}

@onready var ball = $Ball
var state = State.IDLE

var _direction: Vector2
var _velocity: Vector2

func _physics_process(delta):
	if state == State.SHOOTING:
		position += _direction * Globals.SHOOTING_SPEED

func shoot(direction: Vector2):
	print("Shooting ", ball.frame)
	_direction = direction
	state = State.SHOOTING
	ball.area_entered.connect(_on_ball_area_entered)


func _on_ball_area_entered(area):
	var normal = (ball.global_position - area.global_position).normalized().rotated(-area.get_global_transform().get_rotation())
	collided.emit(ball, area, normal)	
	ball.area_entered.disconnect(_on_ball_area_entered)
	queue_free()
	
