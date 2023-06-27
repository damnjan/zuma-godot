extends Node

enum { START, END }

var SPEED_SCALE := 1.0
var NUMBER_OF_COLORS := 4
var TOTAL_NUMBER_OF_BALLS := 200
var INITIAL_NUMBER_OF_BALLS := 100
var ORIGINAL_BALL_WIDTH := 92.0
var BALL_WIDTH := ORIGINAL_BALL_WIDTH
var MAX_FORWARDS_SPEED := 190.0 * SPEED_SCALE
var MAX_BACKWARDS_SPEED := MAX_FORWARDS_SPEED * 40
var BACKWARDS_ACCELERATION := MAX_FORWARDS_SPEED * 40
var SHOOTING_SPEED := 3600.0 * SPEED_SCALE
var MIN_CONSECUTIVE_MATCH := 3
var GOING_BACKWARDS_DELAY := 0.5 / SPEED_SCALE
var PROGRESS_LERP_WEIGHT := 12 * SPEED_SCALE
var SAME_CONSECUTIVE_BALL_CHANCE := 0.3
var SPRING_CONSTANT := 5
var TONGUE_SPEED := 3600.0 * SPEED_SCALE

func update_speed_values():
	MAX_FORWARDS_SPEED = 190.0 * SPEED_SCALE
	MAX_BACKWARDS_SPEED = MAX_FORWARDS_SPEED * 40
	BACKWARDS_ACCELERATION = MAX_FORWARDS_SPEED * 40
	SHOOTING_SPEED = 3600.0 * SPEED_SCALE
	GOING_BACKWARDS_DELAY = 0.5 / SPEED_SCALE
	PROGRESS_LERP_WEIGHT = 12 * SPEED_SCALE
	TONGUE_SPEED = 3600.0 * SPEED_SCALE

var current_level: Level

var hidden_follows = {}
var score = 0
var combo = 0

const color_dict = {
	0: Color8(28,105,253, 100),
	1: Color8(0, 156, 76, 100),
	2: Color8(255,193,2, 100),
	3: Color8(216,42,87, 100)
}

func _emit_hidden_count():
	var hidden_count = {
		START: 0,
		END: 0
	}
	for location in hidden_follows.values():
		hidden_count[location] += 1
	Events.hidden_follows_updated.emit(hidden_count)
	
				

func _ready():
	var current_scene = get_tree().current_scene
	if current_scene is Level:
		current_level = current_scene
				
func check_collision_with_follows(object: Node2D, self_radius: float, callback: Callable):
	for ball in get_tree().get_nodes_in_group('visible_balls'):
		if object.global_position.distance_to(ball.global_position) < Globals.BALL_WIDTH / 2 + self_radius:
			callback.call(ball)
			return


func on_follow_hidden(follow: FollowingBall):
	var location
	if follow.progress_ratio >= 1:
		location = END
	elif follow.current_progress <= 0:
		location = START
	else:
		return
	hidden_follows[follow] = location
	_emit_hidden_count()
	

func on_follow_shown(follow: FollowingBall):
	if !hidden_follows.has(follow):
		return
	hidden_follows.erase(follow)	
	_emit_hidden_count()
	

