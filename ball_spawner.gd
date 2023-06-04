extends Node2D

signal clicked(ball: Ball, collider, normal)

var BallScene = preload("res://Ball.tscn")

@onready var shape_cast_2d: ShapeCast2D = $ShapeCast2D
@onready var line_2d = $"Line2D"

var ball: Ball
var collider
var rotated_normal: Vector2
var ball_velocity: Vector2
var shooting_direction: Vector2

func create_ball():
	ball = BallScene.instantiate()
	get_parent().add_child.call_deferred(ball)
	shape_cast_2d.add_exception(ball)
	ball.position = self.position
	ball.area_entered.connect(_on_ball_area_entered)
	ball_velocity *= 0
	return ball
	

# Called when the node enters the scene tree for the first time.
func _ready():
	create_ball()
	ball.frame = 1
	line_2d.add_point(Vector2.ZERO)
	line_2d.add_point(get_global_mouse_position())

	
func _on_ball_area_entered(area):
	var normal = (ball.global_position - area.global_position).normalized().rotated(-area.get_global_transform().get_rotation())
	print("Normal: ", normal)
	print("Parent: ", area.get_parent())
	ball.get_parent().remove_child(ball)
	clicked.emit(ball, area, normal)	
	ball.area_entered.disconnect(_on_ball_area_entered)

	
func _physics_process(delta):
	ball.position += ball_velocity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shooting_direction =  Vector2(get_local_mouse_position() - shape_cast_2d.position).normalized()
#	shape_cast_2d.target_position = shooting_direction * 4000
	line_2d.set_point_position(1, shooting_direction * 4000 + shape_cast_2d.position)
#	shape_cast_2d.position = ball.position
#	shape_cast_2d.target_position = ball.position
#	if shape_cast_2d.collision_result.size():
#		var result = shape_cast_2d.collision_result[0]
#		collider = result.collider
#		ball.position = result.point  + result.normal * 50
#		rotated_normal = result.normal.rotated(-result.collider.get_global_transform().get_rotation())
#	else:
#		ball.position = self.position
#		collider = null
##		rotated_normal = null
		
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			ball_velocity = shooting_direction * 100
			await get_tree().create_timer(0.5).timeout 
			create_ball()
#			clicked.emit(ball, collider, rotated_normal)
#			get_parent().remove_child(ball)
#			create_ball()
