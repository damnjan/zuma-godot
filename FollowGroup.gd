class_name FollowGroup

enum State {
	FORWARDS, WAITING, BACKWARDS
}

var prev_group: FollowGroup
var next_group: FollowGroup

var is_removed = false
var state = State.FORWARDS
var items: Array[FollowingBall]
var global_progress = 0
var current_speed: float
var acceleration_curve: Curve = preload("res://acceleration_curve.tres")

var _follows_to_delete: Array[FollowingBall]
var _is_inserting = false


# a and b are indexes of first and last marble that explodes
func split_group(a, b):
	var new_group = FollowGroup.new()
	new_group.prev_group = self
	new_group.next_group = next_group
	new_group.items = items.slice(b)	
	items = items.slice(0, a)
	
	if next_group:
		next_group.prev_group = new_group
		
	next_group = new_group
	
	
	new_group.global_progress = new_group.items[0].progress
		
	return new_group


func add_item(item: FollowingBall, index, ignore_check = false):
	_is_inserting = true
	if index != null:
		items.insert(index, item)
	else:
		items.append(item)
		index = items.size() - 1
	item.progress = index * Globals.BALL_WIDTH + global_progress
	if !ignore_check:
		GlobalTimer.create_async(func(): _check_for_matches_from(index); _is_inserting = false, 0.2)

func change_state(next_state: State):
	state = next_state
	
func remove():
	if prev_group:
		prev_group.next_group = next_group
	if next_group:
		next_group.prev_group = prev_group
	is_removed = true

func merge_next_group():
	var last_index = items.size() - 1
	items.append_array(next_group.items)
	current_speed += next_group.current_speed	
	next_group.remove()
	_check_for_matches_from(last_index, true)

var curve_time: float = 0.0
var last_speed = current_speed

func physics_process(delta):
	match state:
		State.FORWARDS:
			
			if (last_speed <= 0 and current_speed > 0):
				curve_time = 0
				
			last_speed = current_speed
			curve_time += delta
			
			var acceleration = acceleration_curve.sample(curve_time) * 1000 if current_speed >= 0 else 4000
			
			current_speed = min(current_speed + acceleration * delta, Globals.FORWARDS_SPEED)
				
			global_progress += current_speed * delta
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1 if _is_inserting else 1)

			if next_group != null and last_item().progress >= next_group.first_item().progress - Globals.BALL_WIDTH:
				merge_next_group()
		
		State.BACKWARDS:
#			if current_speed > -Globals.BACKWARDS_SPEED:
#				current_speed -= 1500 * delta
			current_speed = -Globals.BACKWARDS_SPEED	
			global_progress += current_speed * delta
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1)

			if prev_group != null and first_item().progress <= prev_group.last_item().progress + Globals.BALL_WIDTH and prev_group.state != State.FORWARDS:
				prev_group.merge_next_group()
				
		State.WAITING:
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1)
	
	

func first_item() -> FollowingBall:
	return items.front()
	
func last_item() -> FollowingBall:
	return items.back()
		
func _check_for_matches_from(index: int, is_merge = false):
	if index >= items.size():
		print("THIS IS BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD")
		return
	var start = index
	var end = index # end is non inclusive
	while start -1 >= 0 and items[start - 1].frame == items[index].frame:
		start -= 1
	while end < items.size() and items[end].frame == items[index].frame:
		end += 1
#	print({ "index": index, "start": start, "end": end})
	if end - start >= Globals.MIN_CONSECUTIVE_MATCH:
		if is_merge and end == index + 1:
			print("Skipping check")
			return
		_explode_balls(start, end)


func _explode_balls(start: int, end: int):
	Globals.shake_camera()
	var items_to_remove = items.slice(start, end)
	
	if start > 0 and end < items.size():
		var group = split_group(start, end)
		group.state = FollowGroup.State.WAITING
		if group.prev_group and group.first_item().frame == group.prev_group.last_item().frame:
			GlobalTimer.create_async(func(): group.state = State.BACKWARDS, 0.5)
	elif start == 0:
		print("Removing from the start")
		global_progress += items_to_remove.size() * Globals.BALL_WIDTH
	else:
		print("This is probably a whole group removed :)")
		
	for follow in items_to_remove:
		follow.kill_ball()
		items.erase(follow)
		if items.is_empty():
			remove()
