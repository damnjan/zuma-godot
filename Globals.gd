extends Node

enum { START, END }

const NUMBER_OF_COLORS = 4
const TOTAL_NUMBER_OF_BALLS = 200
const INITIAL_NUMBER_OF_BALLS = 100
const ORIGINAL_BALL_WIDTH := 92.0
const BALL_WIDTH := ORIGINAL_BALL_WIDTH
const MAX_FORWARDS_SPEED := 190.0
const MAX_BACKWARDS_SPEED := MAX_FORWARDS_SPEED * 40
const BACKWARDS_ACCELERATION = MAX_FORWARDS_SPEED * 40
const SHOOTING_SPEED = 3600.0
const MIN_CONSECUTIVE_MATCH = 3
const GOING_BACKWARDS_DELAY = 0.5
const PROGRESS_LERP_WEIGHT = 12
const SAME_CONSECUTIVE_BALL_CHANCE = 0.3
const SPRING_CONSTANT = 5
const TONGUE_SPEED = 3600.0

var hidden_follows = {}
var score = 0
var combo = 0

const color_dict = {
	0: Color8(28,105,253, 100),
	1: Color8(0, 156, 76, 100),
	2: Color8(255,193,2, 100),
	3: Color8(216,42,87, 100)
}
	
var all_groups: Array[FollowGroup] = []

func _emit_hidden_count():
	var hidden_count = {
		START: 0,
		END: 0
	}
	for location in hidden_follows.values():
		hidden_count[location] += 1
	Events.hidden_follows_updated.emit(hidden_count)
	
# return true in callback if you want to exit early
func for_each_visible_ball(callback: Callable):
	for group in all_groups:
		if group.is_removed:
			continue
		for ball in group.items:
			if ball.is_hidden:
				continue
			var should_return = callback.call(ball)
			if should_return:
				return
				
func check_collision_with_follows(object: Node2D, self_radius: float, callback: Callable):
	for_each_visible_ball(func (ball):
		if object.global_position.distance_to(ball.global_position) < Globals.BALL_WIDTH / 2 + self_radius:
			callback.call(ball)
			return true	
	)

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
	
