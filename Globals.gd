extends Node

signal hidden_follows_updated(value)

enum { START, END }

const BALL_WIDTH := 92.0
const FORWARDS_SPEED := 100.0
const BACKWARDS_SPEED := 1500.0
const SHOOTING_SPEED = 60.0
const MIN_CONSECUTIVE_MATCH = 3
const GOING_BACKWARDS_DELAY = 0.5
const CHECKING_DELAY = 0.15 # time to animate insertion of a ball
const PROGRESS_LERP_WEIGHT = 0.2

var hidden_follows = {}

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

func shake_camera():
	var first_node = get_tree().root.get_node("Node2D")
	first_node.get_node('PoppingSound').play()
	first_node.get_node("Shaker").start()
	
func play_merge_sound():
	get_tree().root.get_node("Node2D").get_node("MergeSound").play()
