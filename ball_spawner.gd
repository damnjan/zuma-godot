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
	shooting_direction = global_position.direction_to(get_global_mouse_position()).normalized()
	line_2d.set_point_position(1, shooting_direction * 4000 )

func _input(event):
	if shooting_ball == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT :
			shooting_ball.shoot(shooting_direction)
			shooting_ball = null
			GlobalTimer.create_async(spawn_shooting_ball, 0.2)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			shooting_ball.change_color()

func spawn_shooting_ball():
	shooting_ball = ShootingBallScene.instantiate()
	add_child(shooting_ball)
	shooting_ball.collided.connect(_on_ball_collided)

func _on_ball_collided(ball, area, normal):
	collided.emit(ball, area, normal)
