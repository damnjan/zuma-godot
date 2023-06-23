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

var curve_length := 0.0

# progress should only be updated when we want to visually move the ball
# when the ball is outside of view, we don't need to move it, which impacts performance
# forget that `progress` exists and only use `current_progress`
var _current_progress := progress
var current_progress: float:
	get:
		return _current_progress
	set(value):
		_current_progress = value
		if !is_hidden:
			progress = value

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
	curve_length = get_parent().curve.get_baked_length()
	
	
func _physics_process(delta):
	if is_dying:
		return
		
	_update_progress(delta)	
	_update_visibility()

	if origin_position:
		ball.global_position = lerp(ball.global_position, global_position, Globals.PROGRESS_LERP_WEIGHT * delta)

	var distance = ball.global_position.distance_to(global_position)
	var is_settled = distance < DISTANCE_TOLERANCE
	if is_settled and !is_ready_for_checking:
		# the ball has settled in the chain visually (approximately) so it means it is ready
		_set_ready_for_checking()
		

		
	
		
func _update_progress(delta):
	var next_progress = group.global_progress + index * Globals.BALL_WIDTH
	# when being hit from a group that moves backwards, don't interpolate because it looks weird
	if !group.is_inserting and group.state == FollowGroup.State.FORWARDS and group.current_speed < 0:
		current_progress = next_progress
	else:
		current_progress = lerpf(current_progress, next_progress, Globals.PROGRESS_LERP_WEIGHT * delta)
		
	
func _set_ready_for_checking():
	is_ready_for_checking = true
	ready_for_checking.emit()
		
# hides/shows the ball and disables/enables collision if outside the path
func _update_visibility():
	var new_value = current_progress >= curve_length or current_progress <= 0
	if new_value != is_hidden:
		is_hidden = new_value
		if is_hidden:
			hide()
			Globals.on_follow_hidden(self)
		else:
			show()
			progress = current_progress # update visual progress now that visibility changed
			Globals.on_follow_shown(self)
		
	
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
