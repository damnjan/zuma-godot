extends Node2D

@onready var path_2d: Path2D = $Path2D
@onready var insert_sound = $InsertSound
@onready var seed_label = $SeedLabel

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")

var first_group = FollowGroup.new()
var follows: Array[FollowingBall]
var global_progress = 0.0
var _split_pointers: Array[int] # points where split started (index of first item for deletion)
var _going_backwards = false

	
func _draw():
	print("Drawing")
	draw_polyline(path_2d.curve.get_baked_points(), Color(1, 1, 1), 20, true)

func _ready():
	var n = randi()
	seed(n)	
	print("Seed : ", n)
	seed_label.text = str(n)
	
	for i in 50:
		_add_follow(null, null, first_group, true)
		
		
		
func _physics_process(delta):
	_check_first_group()
	var groups = []
	var next: FollowGroup = first_group
	
	while next:
		groups.append(next)
		next.physics_process(delta)
		next = next.next_group
		
	
	
func _check_first_group():
	if first_group and first_group.is_removed and first_group.next_group:
		first_group = first_group.next_group
		first_group.state = FollowGroup.State.FORWARDS

func _add_follow(frame = null, index = null, group = first_group, ignore_check = false, ball_global_position = null):
	var follow: FollowingBall = FollowingBall.new(frame)
	follow.origin_position = ball_global_position
	path_2d.add_child.call_deferred(follow)
	group.add_item(follow, index, ignore_check)

	return follow


func _on_ball_spawner_collided(ball, collider, normal):
	if !collider:
		return
	insert_sound.play()
	var group = first_group
	while group:
		for i in group.items.size():
			var current_ball = group.items[i].ball
			if current_ball == collider:
				var insert_index = i if normal.x < 0 else i + 1
				_add_follow(ball.frame, insert_index, group, false, ball.global_position)
				break
		group = group.next_group
