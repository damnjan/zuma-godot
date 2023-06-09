extends PathFollow2D

class_name FollowingBall

signal ready_for_checking

const DISTANCE_TOLERANCE = 10

var BallScene = preload("res://Ball.tscn")

var ball: Ball
var origin_position

var is_dying = false
var is_ready_for_checking = false
var group: FollowGroup

var frame:
	get:
		return ball.frame
	set(value):
		ball.frame = value

func _init(frame):
	loop = false
	ball = BallScene.instantiate()
	if frame != null:
		ball.frame = frame
	add_child(ball)
	ball.exploded.connect(_on_ball_exploded)
	
func _set_ready_for_checking():
	is_ready_for_checking = true
	ready_for_checking.emit()
	
func _ready():
	if origin_position:
		ball.global_position = origin_position
		
	
func _physics_process(delta):
	if origin_position:
		ball.global_position = lerp(ball.global_position, global_position, Globals.PROGRESS_LERP_WEIGHT)

	var distance = ball.global_position.distance_to(global_position)
	var is_settled = distance < DISTANCE_TOLERANCE
	if is_settled and !is_ready_for_checking:
		# the ball has settled in the chain visually (approximately) so it means it is ready
		_set_ready_for_checking()

func _on_ball_exploded():
	queue_free()

	
func kill_ball():
	is_dying = true
	ball.explode()
	
func hide_and_disable():
	hide()
	if ball.collision_shape:
		ball.collision_shape.disabled = true
	
func show_and_enable():
	show()
	if ball.collision_shape:
		ball.collision_shape.disabled = false
	
