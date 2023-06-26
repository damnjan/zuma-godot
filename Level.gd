extends Node2D

class_name Level

@onready var path_2d: Path2D = $Path2D
@onready var seed_label = $SeedLabel
@onready var end_count_label = $EndCountLabel
@onready var shaker = $Shaker
@onready var group_manager = $GroupManager

@export var initial_balls: String

@export_range(0.1, 2, 0.1) var SPEED_SCALE = 1.0:
	set(value):
		print("set")
		Globals.SPEED_SCALE = value
		Globals.update_speed_values()
	get:
		return Globals.SPEED_SCALE

const BallScene = preload("res://Ball.tscn")
const ComboScene = preload("res://Combo.tscn")
const ScorePopupScene = preload("res://ScorePopup.tscn")

#var first_group: FollowGroup
var game_ready = false

func _init():
	_seed()
	
	Events.balls_exploding.connect(_on_balls_exploding)
	Events.hidden_follows_updated.connect(func(hidden_count):
		var hidden_end = hidden_count[Globals.END]
		end_count_label.set_value(hidden_end)
	)
	Events.shooting_ball_collided.connect(_on_shooting_ball_collided)
	
func _ready():
	print("Level ready")
	var arr: PackedStringArray
	var initial_balls_array = Utils.split_to_int_array(initial_balls) if initial_balls else null
	_generate_balls( initial_balls_array)
		
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
		
	var first_group = group_manager.create_first_group()
	first_group.global_progress = -total_number * Globals.BALL_WIDTH
	first_group.add_items(initial_follows)
	
#	first_group.global_progress = -total_number * Globals.BALL_WIDTH
		
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)	
	tween.tween_property(first_group, "global_progress", target_global_progress, 2)

func _on_shooting_ball_collided(ball: Ball, collided_follow: FollowingBall):
	AudioManager.play(AudioManager.insert_sound)
	Globals.combo = 0

		
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
	
