extends Node2D

@onready var path_2d: Path2D = $Path2D

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")

var follows: Array[FollowingBall]
var global_progress = 0.0
var _follows_to_delete: Array[FollowingBall] = []
var _split_pointers: Array[int] # points where split started (index of first item for deletion)
var _going_backwards = false

func _ready():
	seed(123)
#	for i in [0,0,1,1,0,0]:
#	for i in 50:
	for i in [0,1,3,2,3,0,0,1,1,0,0,3,3,0,0,1,1,3,0,1,0,1,2,0,0,1,3,1,0,0,1,2,3]:
		var b = BallScene.instantiate()
		b.frame = i
		_add_follow(b)
	
		
func _physics_process(delta):
	_move_follows(delta)
	if not _going_backwards: 
		_check_for_matches()

# I have noooo idea why but this works kinda
func _move_follows(delta):
	if not _going_backwards:
		global_progress += 100 * delta
		
	_going_backwards = false
	for i in follows.size():
		var new_progress = i * BALL_WIDTH
		if i > 0:
			var diff = follows[i].progress - follows[i - 1].progress
			if diff > BALL_WIDTH + 1:
				new_progress = i * BALL_WIDTH + global_progress - diff
				_going_backwards = true
				
		if not _going_backwards:
			new_progress += global_progress
		
		follows[i].progress = lerpf(follows[i].progress, new_progress, 0.1)

# check for 3 or more matching
func _check_for_matches():
	if not _follows_to_delete.is_empty():
		return
	for i in follows.size():
		var consecutive = []
		var x = i
		while x < follows.size() and follows[x].ball.frame == follows[i].ball.frame:
			consecutive.append(follows[x])
			x += 1
		if consecutive.size() >= 3:
			_follows_to_delete.append_array(consecutive)
			$Shaker.start()
			for follow in consecutive:
				follow.kill_ball()
			_split_pointers.append(x - consecutive.size())
			print(_split_pointers)
			break
			
	
func _on_ball_died(follow):
	follows.erase(follow)
	_follows_to_delete.erase(follow)

func _add_follow(ball, index = null):
	var follow = FollowingBall.new()
	follow.add_ball(ball)
	ball.died.connect(_on_ball_died)
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
