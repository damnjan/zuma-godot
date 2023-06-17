extends Node2D

@onready var path_2d: Path2D = $Path2D
@onready var seed_label = $SeedLabel
@onready var end_count_label = $EndCountLabel
@onready var shaker = $Shaker

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")
const ComboScene = preload("res://Combo.tscn")
const ScorePopupScene = preload("res://ScorePopup.tscn")

var first_group = FollowGroup.new()
var game_ready = false

func _init():
	Events.balls_exploding.connect(_on_balls_exploding)
	Events.shooting_ball_collided.connect(_on_shooting_ball_collided)
	Events.hidden_follows_updated.connect(func(hidden_count):
#		var hidden_start = hidden_count[Globals.START]
		var hidden_end = hidden_count[Globals.END]
		end_count_label.set_value(hidden_end)
	)

func _ready():
	_seed()
	_generate_balls(
#		[1,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,2,2,2,2,2,2,2,2,2,1]
	)
		
func _physics_process(delta):
	_check_first_group()
	var groups = []
	var next: FollowGroup = first_group
	
	while next:
		groups.append(next)
		next.physics_process(delta)
		next = next.next_group
		
func _seed():
	var n = randi()
	seed(n)	
	seed_label.text = str(n)
	print("Seed : ", n)	
		
func _generate_balls(test_data = null):
	var total_number = test_data.size() if test_data else Globals.TOTAL_NUMBER_OF_BALLS
	var initial_number = test_data.size() if test_data else Globals.INITIAL_NUMBER_OF_BALLS
	var target_global_progress = -(total_number - initial_number) * Globals.BALL_WIDTH
	first_group.global_progress = -total_number * Globals.BALL_WIDTH	
	
	for i in total_number:
		_add_follow(test_data[i] if test_data else null, null, first_group, true)
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)	
	tween.tween_property(first_group, "global_progress", target_global_progress, 2)
	
func _check_first_group():
	if first_group and first_group.is_removed and first_group.next_group:
		first_group = first_group.next_group
		first_group.state = FollowGroup.State.FORWARDS

func _add_follow(frame = null, index = null, group = first_group, instant_ready = false, ball_global_position = null):
	if frame == null and !group.items.is_empty() and randf() < Globals.SAME_CONSECUTIVE_BALL_CHANCE:
		frame = group.items.back().frame
	var follow: FollowingBall = FollowingBall.new(frame)

	follow.origin_position = ball_global_position
	group.add_item(follow, index, instant_ready)
	path_2d.add_child.call_deferred(follow) # not sure if call deferred is needed, but errors are logged otherwise

	return follow


func _on_shooting_ball_collided(ball, collider, normal):
	if !collider:
		print("no collider")
		return
	AudioManager.play(AudioManager.insert_sound)
	var follow = collider.get_parent()
	var group = follow.group
	var i = group.items.find(follow)
	var insert_index = i if normal.x < 0 else i + 1
	_add_follow(ball.frame, insert_index, group, false, ball.global_position)

		
		
func _on_balls_exploding(balls):
	var middle_ball = balls[balls.size() / 2]
	Globals.combo += 1
	var score = 10 * balls.size() * Globals.combo
	Globals.score += score
	$ScoreLabel.set_value(Globals.score)
	
	var score_popup = ScorePopupScene.instantiate()
	score_popup.value = score
	add_child(score_popup)
	score_popup.global_position = middle_ball.global_position
	
	
	shaker.stop()
	shaker.max_value = 0 + (Globals.combo - 1) * 10
	shaker.duration = 0.2 + (Globals.combo - 1) * 0.1
	shaker.start()
	AudioManager.popping_sound.pitch_scale = 1 + (Globals.combo - 1) * 0.1
	AudioManager.play(AudioManager.popping_sound)
	
	if Globals.combo > 1:
		
		var combo: Node2D = ComboScene.instantiate()
		combo.value = (Globals.combo)
		add_child(combo)
		combo.global_position = middle_ball.global_position
	
