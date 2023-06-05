extends Node2D

signal collided(ball: Ball, collider, normal)

var ShootingBallScene = preload("res://ShootingBall.tscn")

var shooting_ball: ShootingBall
var shooting_direction: Vector2

@onready var line_2d = $"Line2D"

func _ready():
	spawn_shooting_ball()
	line_2d.add_point(Vector2.ZERO)
	line_2d.add_point(get_global_mouse_position())


func _process(delta):
	shooting_direction =  Vector2(get_local_mouse_position()).normalized()
	line_2d.set_point_position(1, shooting_direction * 4000 )

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shooting_ball.shoot(shooting_direction)
			spawn_shooting_ball()

func spawn_shooting_ball():
	shooting_ball = ShootingBallScene.instantiate()
	add_child(shooting_ball)
	shooting_ball.collided.connect(_on_ball_collided)

func _on_ball_collided(ball, area, normal):
	collided.emit(ball, area, normal)
