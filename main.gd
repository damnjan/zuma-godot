extends Node2D

@onready var path_2d: Path2D = $Path2D
@onready var insert_sound = $InsertSound
@onready var seed_label = $SeedLabel
@onready var start_count_label = $StartCountLabel
@onready var end_count_label = $EndCountLabel
@onready var popping_sound = $PoppingSound
@onready var shaker = $Shaker

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")
var ComboScene = preload("res://Combo.tscn")

var first_group = FollowGroup.new()
var follows: Array[FollowingBall]
var global_progress = 0.0
var _split_pointers: Array[int] # points where split started (index of first item for deletion)
var _going_backwards = false

func _init():
	Globals.balls_exploded.connect(_on_balls_exploded)

func _ready():
	var n = randi()
	seed(n)	
	print("Seed : ", n)
	seed_label.text = str(n)
	
	
	first_group.global_progress = -(Globals.TOTAL_NUMBER_OF_BALLS - Globals.INITIAL_NUMBER_OF_BALLS) * Globals.BALL_WIDTH
	for i in Globals.TOTAL_NUMBER_OF_BALLS:
		_add_follow(null, null, first_group, true)
#
#	for i in [0,0,1,0,1,0,1,2,3,3,3,3,3,3,3,3,2,2,1,3,3,1,2]:
#		_add_follow(i, null, first_group, true)
		
	Globals.hidden_follows_updated.connect(func(hidden_count):
		var hidden_start = hidden_count[Globals.START]
		var hidden_end = hidden_count[Globals.END]
		start_count_label.set_value(hidden_start)
		end_count_label.set_value(hidden_end)
	)
		
		
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

func _add_follow(frame = null, index = null, group = first_group, instant_ready = false, ball_global_position = null):
	var follow: FollowingBall = FollowingBall.new(frame)
	follow.origin_position = ball_global_position
	group.add_item(follow, index, instant_ready)
	path_2d.add_child(follow) # try add_child.call_deferred(follow) if run into weird bugs

	return follow


func _on_ball_spawner_shooting_ball_collided(ball, collider, normal):
	if !collider:
		print("no collider")
		return
	insert_sound.play()
	var follow = collider.get_parent()
	var group = follow.group
	var i = group.items.find(follow)
	var insert_index = i if normal.x < 0 else i + 1
	_add_follow(ball.frame, insert_index, group, false, ball.global_position)

		
		
func _on_balls_exploded(balls):
	Globals.combo += 1
	shaker.stop()
	shaker.max_value = 0 + (Globals.combo - 1) * 10
	shaker.duration = 0.2 + (Globals.combo - 1) * 0.1
	shaker.start()
	popping_sound.pitch_scale = 1 + (Globals.combo - 1) * 0.1
	popping_sound.play()
	
	if Globals.combo > 1:
		var ball = balls[balls.size() / 2]
		var combo: Node2D = ComboScene.instantiate()
		combo.value = (Globals.combo)
		add_child(combo)
		combo.global_position = ball.global_position
	
