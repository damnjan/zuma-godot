extends Node

signal hidden_follows_updated(value)
signal balls_exploded(balls)

enum { START, END }

const NUMBER_OF_COLORS = 4
const TOTAL_NUMBER_OF_BALLS = 150
const INITIAL_NUMBER_OF_BALLS = 50
const BALL_WIDTH := 92.0
const FORWARDS_SPEED := 150.0
const MAX_BACKWARDS_SPEED := FORWARDS_SPEED * 20
const BACKWARDS_ACCELERATION = FORWARDS_SPEED * 20
const SHOOTING_SPEED = 50.0
const MIN_CONSECUTIVE_MATCH = 3
const GOING_BACKWARDS_DELAY = 0.5
const PROGRESS_LERP_WEIGHT = 0.2
const SAME_CONSECUTIVE_BALL_CHANCE = 0.3

var hidden_follows = {}
var score = 0
var combo = 0

func _emit_hidden_count():
	var hidden_count = {
		START: 0,
		END: 0
	}
	for location in hidden_follows.values():
		hidden_count[location] += 1
	hidden_follows_updated.emit(hidden_count)

func on_follow_hidden(follow: FollowingBall):
	var location
	if follow.progress_ratio >= 1:
		location = END
	elif follow.progress <= 0:
		location = START
	else:
		return
	hidden_follows[follow] = location
	_emit_hidden_count()
	

func on_follow_shown(follow: FollowingBall):
	if !hidden_follows.has(follow):
		return
	var location = hidden_follows[follow]
	hidden_follows.erase(follow)	
	_emit_hidden_count()
	
func play_merge_sound():
	get_tree().root.get_node("Node2D").get_node("MergeSound").play()
