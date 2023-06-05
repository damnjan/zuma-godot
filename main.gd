extends Node2D

@onready var path_2d: Path2D = $Path2D

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")

var first_group = FollowGroup.new()
var follows: Array[FollowingBall]
var global_progress = 0.0
var _follows_to_delete: Array[FollowingBall] = []
var _split_pointers: Array[int] # points where split started (index of first item for deletion)
var _going_backwards = false

func _ready():
	seed(123)
#	for i in [0,0,1,1,0,0]:
	for i in 50:
#	for i in [0,1,3,2,3,0,0,1,1,0,0,3,3,0,0,1,1,3,0,1,0,1,2,0,0,1,3,1,0,0,1,2,3]:
#	for i in [0]:
		var b = BallScene.instantiate()
#		b.frame = i
		_add_follow(b)
		
	
		
func _physics_process(delta):
	var next: FollowGroup = first_group
	while next:
		next.physics_process(delta)
		next = next.next_group


func _add_follow(ball, index = null, group = first_group):
	var follow = FollowingBall.new()
	follow.add_ball(ball)
	path_2d.add_child.call_deferred(follow)
	group.add_item(follow, index)

	return follow


func _on_ball_spawner_collided(ball, collider, normal):
	if !collider:
		return
	var group = first_group
	while group:
		for i in group.items.size():
			var current_ball = group.items[i].ball
			if current_ball == collider:
				var new_ball = ball.duplicate()
				new_ball.position *= 0
				new_ball.frame = ball.frame
				
				var insert_index = i if normal.x < 0 else i + 1
				_add_follow(new_ball, insert_index, group)
				
				break
		group = group.next_group
