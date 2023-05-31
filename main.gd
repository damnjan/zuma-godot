extends Node2D

@onready var path_2d: Path2D = $Path2D

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")

var follows: Array[FollowingBall] = []
var global_progress = 0.0
var _follows_to_delete: Array[FollowingBall] = []

func _ready():
	seed(123)
	for i in [0,0,1,1,0,0]:
		var b = BallScene.instantiate()
		b.frame = i
		_add_follow(b)
		
func _delete_dead_follows():
	for follow_to_remove in _follows_to_delete:
		follows.erase(follow_to_remove)
		follow_to_remove.ball.died.connect(_on_ball_died)
		follow_to_remove.ball.die(follow_to_remove)
	_follows_to_delete = []
	
		
func _physics_process(delta):
	_move_follows(delta)
	_check_for_matches()
	_delete_dead_follows()	

func _move_follows(delta):
	global_progress += 100 * delta
	for i in follows.size():
		var new_progress = i * BALL_WIDTH + global_progress
		follows[i].progress = lerpf(follows[i].progress, new_progress, 0.2)

# check for 3 or more matching
func _check_for_matches():
	for i in follows.size():
		var consecutive = []
		var x = i
		while x < follows.size() and follows[x].ball.frame == follows[i].ball.frame:
			consecutive.append(follows[x])
			x += 1
		if consecutive.size() >= 3:
			_follows_to_delete.append_array(consecutive)
	
func _on_ball_died(follow):
	follows.erase(follow)

func _add_follow(ball, index = null):
	var follow = FollowingBall.new()
	follow.add_ball(ball)
	path_2d.add_child(follow)
	if index == null:
		follows.append(follow)
	else:
		follow.progress = follows[index - 1 if index > 0 else 0].progress
		follows.insert(index, follow)
	return follow

func _on_ball_spawner_clicked(ball, collider, normal):
	if !collider:
		return
	for i in follows.size():
		var current_ball = follows[i].ball
		if current_ball == collider:
			var new_ball = ball.duplicate()
			new_ball.position *= 0
			new_ball.frame = ball.frame
			
			var insert_index = i if normal.x < 0 else i + 1
			_add_follow(new_ball, insert_index)
			
			break
