extends Node2D

signal clicked(ball: Ball, collider, normal)

var BallScene = preload("res://Ball.tscn")

@onready var shape_cast_2d: ShapeCast2D = $ShapeCast2D
@onready var line_2d = $"Line2D"

var ball: Ball
var collider
var rotated_normal: Vector2

func create_ball():
	ball = BallScene.instantiate()
	get_parent().add_child.call_deferred(ball)
	shape_cast_2d.add_exception(ball)
	return ball
	

# Called when the node enters the scene tree for the first time.
func _ready():
	create_ball()
	ball.frame = 1
	line_2d.add_point(Vector2.ZERO)
	line_2d.add_point(get_global_mouse_position())

	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shape_cast_2d.target_position = Vector2(get_local_mouse_position() - shape_cast_2d.position).normalized() * 4000
	line_2d.set_point_position(1, shape_cast_2d.target_position + shape_cast_2d.position)
	if shape_cast_2d.collision_result.size():
		var result = shape_cast_2d.collision_result[0]
		collider = result.collider
		ball.position = result.point  + result.normal * 50
		rotated_normal = result.normal.rotated(-result.collider.get_global_transform().get_rotation())
	else:
		ball.position = self.position
		collider = null
#		rotated_normal = null
		
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(ball, collider, rotated_normal)
			get_parent().remove_child(ball)
			create_ball()
