extends PathFollow2D

class_name FollowingBall

signal ready_for_checking

const DISTANCE_TOLERANCE = 10


var BallScene = preload("res://Ball.tscn")

var ball: Ball = BallScene.instantiate()
var index: int = -1

var is_dying = false
var is_ready_for_checking = true
var group: FollowGroup

var is_hidden = true # visually hidden and collision disabled

var _curve_length := 0.0 # Path2D curve length

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
		assert(false, "Why would you do that? :)")
		ball.frame = value
		
		
var _origin_position = null # this is set when ball is being added from colliding, for animation purpose
var _origin_rotation = null
func _init(ball_frame, origin_position = null, origin_rotation = null):
	loop = false
	if ball_frame != null:
		ball.frame = ball_frame
	if origin_position:
		_origin_position = origin_position
		is_ready_for_checking = false		
	_origin_rotation = origin_rotation
#	_target_rotation = target_rotation
	add_child(ball)
	ball.exploded.connect(_on_ball_exploded)
	
	

func _ready():
	assert(group and index >= 0, "Item must be in a group and have an index set")	
	is_hidden = false
	add_to_group('visible_balls')
	current_progress = index * Globals.BALL_WIDTH + group.global_progress
	if _origin_position:
		ball.position = to_local(_origin_position)
	if _origin_rotation:
		ball.rotation =  _origin_rotation - rotation
	_curve_length = get_parent().curve.get_baked_length()
	
	
func _physics_process(delta):
	if is_dying:
		return
		
	_update_progress(delta)	
	_update_visibility()

	if _origin_position:
		ball.position = lerp(ball.position, Vector2.ZERO, Globals.PROGRESS_LERP_WEIGHT * delta)
	if _origin_rotation:
		ball.rotation = lerp_angle(ball.rotation, 0.0, Globals.PROGRESS_LERP_WEIGHT * delta)
		

	var distance = ball.position.distance_to(Vector2.ZERO)
	var is_settled = distance < DISTANCE_TOLERANCE
	if is_settled and !is_ready_for_checking:
		# the ball has settled in the chain visually (approximately) so it means it is ready
		_set_ready_for_checking()
	
		
func _update_progress(delta):
	var next_progress = group.global_progress + index * Globals.BALL_WIDTH
	current_progress = lerpf(current_progress, next_progress, Globals.PROGRESS_LERP_WEIGHT * delta)	
	# when being hit from a group that moves backwards, don't interpolate because it looks weird (or does it?)
#	if !group.is_inserting and group.state == FollowGroup.State.FORWARDS and group.current_speed < 0:
#		current_progress = next_progress
#	else:
#		current_progress = lerpf(current_progress, next_progress, Globals.PROGRESS_LERP_WEIGHT * delta)
		
	
func _set_ready_for_checking():
	is_ready_for_checking = true
	ready_for_checking.emit()
		
# hides/shows the ball and disables/enables collision if outside the path
func _update_visibility():
	var new_value = current_progress >= _curve_length or current_progress <= 0
	if new_value != is_hidden:
		is_hidden = new_value
		if is_hidden:
			hide()
			remove_from_group('visible_balls')
			Globals.on_follow_hidden(self)
		else:
			show()
			add_to_group('visible_balls')
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
	remove_from_group('visible_balls')
	is_dying = true
	ball.explode()
	
func _on_ball_exploded():
	queue_free()
