extends PathFollow2D

class_name FollowingBall

signal ready_for_checking

const DISTANCE_TOLERANCE = 10

var BallScene = preload("res://Ball.tscn")

var ball: Ball
var origin_position
var index: int

var is_dying = false
var is_ready_for_checking = false
var group: FollowGroup

var is_hidden = false

var frame:
	get:
		return ball.frame
	set(value):
		ball.frame = value

func _init(_frame):
	loop = false
	ball = BallScene.instantiate()
	if _frame != null:
		ball.frame = _frame
	add_child(ball)
	ball.exploded.connect(_on_ball_exploded)
	
func _ready():
	if origin_position:
		ball.global_position = origin_position	
	
func _physics_process(delta):
	if is_dying:
		return
#	_move(delta)
	
	_update_visibility()
	if origin_position:
		ball.global_position = lerp(ball.global_position, global_position, Globals.PROGRESS_LERP_WEIGHT * delta)

	var distance = ball.global_position.distance_to(global_position)
	var is_settled = distance < DISTANCE_TOLERANCE
	if is_settled and !is_ready_for_checking:
		# the ball has settled in the chain visually (approximately) so it means it is ready
		_set_ready_for_checking()
		
	
		
#func _move(delta):
#	var new_progress = group.global_progress + index * Globals.BALL_WIDTH
#	# when being hit from a group that moves backwards, don't interpolate because it looks weird
#	if !group.is_inserting and group.state == FollowGroup.State.FORWARDS and group.current_speed < 0:
#		progress = new_progress
#	else:
#		progress = lerpf(progress, new_progress, Globals.PROGRESS_LERP_WEIGHT * delta)
	
func _set_ready_for_checking():
	is_ready_for_checking = true
	ready_for_checking.emit()
		
# hides/shows the ball and disables/enables collision if outside the path
func _update_visibility():
	var old_value = is_hidden
	var new_value = progress_ratio >= 1 or progress <= 0
	if new_value == old_value:
		return
	is_hidden = new_value
	hide() if is_hidden else show()
	if ball.collision_shape:
		ball.collision_shape.disabled = is_hidden
	Globals.on_follow_hidden(self) if is_hidden else Globals.on_follow_shown(self)
	
func remove_self():
	is_dying = true	
	group.items.erase(self)

	if !group.items.is_empty():
		var next_group = group.next_group
		if index > 0 and index < group.items.size():
			next_group = group.split_group(index)	
		if group._should_rush_backwards():
			group.state = group.State.BACKWARDS
		if next_group and next_group._should_rush_backwards():
			next_group.state = group.State.BACKWARDS
	else:
		group.remove()

	queue_free()	
	
	
func kill_ball():
	is_dying = true
	ball.explode()
	
func _on_ball_exploded():
	queue_free()
