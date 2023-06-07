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
	if index == null:
		index = items.size()

	items.insert(index, item)
	item.group = self		
	
	# if adding at the beginning, don't push others (actually, move everything back)
	if index == 0 and !ignore_check:
		global_progress -= Globals.BALL_WIDTH
		
	item.progress = index * Globals.BALL_WIDTH + global_progress
	
	if ignore_check:
		item.is_ready_for_checking = true
	else:
		## TODO: This is ugly, find a better way
		item.ready_for_checking.connect(func(): 
			item.group._check_for_matches_from_item(item)
		)
		


func change_state(next_state: State):
	state = next_state
	
func remove():
	if prev_group:
		prev_group.next_group = next_group
	if next_group:
		next_group.prev_group = prev_group
	is_removed = true

func merge_next_group():
	var last_item = items.back()
	items.append_array(next_group.items)
	current_speed += next_group.current_speed	
	next_group.remove()
	_check_for_matches_from_item(last_item, true)
	Globals.play_merge_sound()

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
			_update_items_progress()

		State.BACKWARDS:
			current_speed = -Globals.BACKWARDS_SPEED	
			global_progress += current_speed * delta
			_update_items_progress()

		State.WAITING:
			_update_items_progress()
				
	if prev_group != null and first_item().progress <= prev_group.last_item().progress + Globals.BALL_WIDTH and prev_group.state != State.FORWARDS:
		prev_group.merge_next_group()
				
	elif next_group != null and last_item().progress >= next_group.first_item().progress - Globals.BALL_WIDTH:
		merge_next_group()
	

func first_item() -> FollowingBall:
	return items.front()
	
func last_item() -> FollowingBall:
	return items.back()
	
func _update_items_progress():
	for i in items.size():
		items[i].group = self
		var new_progress = global_progress + i * Globals.BALL_WIDTH
		
		# when being hit from a group that moves backwards, don't interpolate because it looks weird
		if state == State.FORWARDS and current_speed < 0:
			items[i].progress = new_progress
		else:
			items[i].progress = lerpf(items[i].progress, new_progress, Globals.PROGRESS_LERP_WEIGHT)

func _check_for_matches_from_item(item: FollowingBall, is_merge = false):
	if item._is_dying:
		print("Dying, skipping.")
		return
	var index = items.find(item)
	var start = index
	var end = index # end is non inclusive
	
	while start -1 >= 0 and items[start - 1].frame == items[index].frame:
		start -= 1
	while end < items.size() and items[end].frame == items[index].frame:
		end += 1
#	print({ "index": index, "start": start, "end": end})
	if end - start >= Globals.MIN_CONSECUTIVE_MATCH:
		if items.slice(start, end).any(func(item): return !item.is_ready_for_checking):
			print("Not ready for checking, skipping.")
			return
		if is_merge and end == index + 1:
			print("is_merge and end == index + 1, skipping.")
			return
			
		_explode_balls(start, end)
	


func _explode_balls(start: int, end: int):
	Globals.shake_camera()
	var items_to_remove = items.slice(start, end)
	
	if start > 0 and end < items.size():
		var group = split_group(start, end)
		group.state = FollowGroup.State.WAITING
		if group.prev_group and group.first_item().frame == group.prev_group.last_item().frame:
			GlobalTimer.create_async(func(): group.state = State.BACKWARDS, Globals.GOING_BACKWARDS_DELAY)
	elif start == 0:
		# offset progress to avoid the whole group moving back
		global_progress += items_to_remove.size() * Globals.BALL_WIDTH

		
	for follow in items_to_remove:
		follow.kill_ball()
		items.erase(follow)
		if items.is_empty():
			remove()
