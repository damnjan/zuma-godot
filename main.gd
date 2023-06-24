extends Node2D

@onready var path_2d: Path2D = $Path2D
@onready var seed_label = $SeedLabel
@onready var end_count_label = $EndCountLabel
@onready var shaker = $Shaker

const BALL_WIDTH = Globals.BALL_WIDTH
const BallScene = preload("res://Ball.tscn")
const ComboScene = preload("res://Combo.tscn")
const ScorePopupScene = preload("res://ScorePopup.tscn")

var first_group: FollowGroup
var game_ready = false

func _init():
	_seed(757992645)
	
	Events.balls_exploding.connect(_on_balls_exploding)
	Events.shooting_ball_collided.connect(_on_shooting_ball_collided)
	Events.hidden_follows_updated.connect(func(hidden_count):
		var hidden_end = hidden_count[Globals.END]
		end_count_label.set_value(hidden_end)
	)
	
func _ready():
	_generate_balls(
#		[1,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,2,2,2,2,2,2,2,2,2,1]
#		[3,2,3,2,3,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,3,0]
#		[0,1,2,3,0,1,2,3,0,0,0,1,1,1,2,2,2,3,3,3,2,2,2,1,1,1,0,0,0,3,2,1,0]
		[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,3]
	)
		
func _physics_process(delta):
	_check_first_group()
	var next: FollowGroup = first_group
	while next:
		next.physics_process(delta)
		next = next.next_group
		
func _seed(n = randi()):
	seed(n)	
	print("Seed : ", n)
	await ready
	seed_label.text = str(n)	
	
		
func _generate_balls(test_data = null):
	var total_number = test_data.size() if test_data else Globals.TOTAL_NUMBER_OF_BALLS
	var initial_number = test_data.size() if test_data else Globals.INITIAL_NUMBER_OF_BALLS
	var target_global_progress = -(total_number - initial_number) * Globals.BALL_WIDTH
	
	var initial_follows: Array[FollowingBall] = []
	for i in total_number:
		var frame = test_data[i] if test_data else null # null means random
		if frame == null and i > 0 and randf() < Globals.SAME_CONSECUTIVE_BALL_CHANCE:
			frame = initial_follows[i - 1].frame
		var follow = FollowingBall.new(frame)
		initial_follows.append(follow)
		path_2d.add_child.call_deferred(follow) # call deferred because we first want to set group items
		
	first_group = FollowGroup.new(initial_follows)
	first_group.global_progress = -total_number * Globals.BALL_WIDTH
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)	
	tween.tween_property(first_group, "global_progress", target_global_progress, 2)
	
func _check_first_group():
	if first_group and first_group.is_removed:
		first_group = first_group.next_group
		if !first_group:
			print("Game Over :)")

func _on_shooting_ball_collided(ball: Ball, collided_follow: FollowingBall, normal: Vector2):
	AudioManager.play(AudioManager.insert_sound)
	Globals.combo = 0
	var group = collided_follow.group
	var i = collided_follow.index
	var insert_index = i if normal.x < 0 else i + 1
	var follow = FollowingBall.new(ball.frame, ball.global_position)

	group.insert_item(follow, insert_index)
	path_2d.add_child(follow)		
		
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
	
