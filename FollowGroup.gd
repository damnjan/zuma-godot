class_name FollowGroup

enum State {
	FORWARDS, WAITING, BACKWARDS
}

var prev_group: FollowGroup
var next_group: FollowGroup

var state = State.FORWARDS
var items: Array[FollowingBall]
var global_progress = 0
var _follows_to_delete: Array[FollowingBall]

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
	if index != null:
		items.insert(index, item)
	else:
		items.append(item)
		index = items.size() - 1
	item.progress = index * Globals.BALL_WIDTH + global_progress
	if !ignore_check:
		GlobalTimer.create_async(func(): _check_for_matches_from(index), 0.1)

func change_state(next_state: State):
	state = next_state
	
func remove():
	if prev_group:
		prev_group.next_group = next_group
	if next_group:
		next_group.prev_group = prev_group

func merge_next_group():
	var last_index = items.size() - 1
	items.append_array(next_group.items)
	next_group.remove()
	_check_for_matches_from(last_index)


func physics_process(delta):
	match state:
		State.FORWARDS:
			global_progress += Globals.FORWARDS_SPEED * delta
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1)

			if next_group != null and last_item().progress >= next_group.first_item().progress - Globals.BALL_WIDTH:
				merge_next_group()
		
		State.BACKWARDS:
			for item in items:
				item.progress -= Globals.BACKWARDS_SPEED * delta
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
		
func _check_for_matches_from(index: int, direction: int = 0):
	var start = index
	var end = index
	if direction <= 0:
		while start -1 >= 0 and items[start - 1].frame == items[index].frame:
			start -= 1
	if direction >= 0:
		while end < items.size() and items[end].frame == items[index].frame:
			end += 1
	print({ "index": index, "start": start, "end": end})
	if end - start >= Globals.MIN_CONSECUTIVE_MATCH:
		_explode_balls(start, end)


func _explode_balls(start: int, end: int):
	Globals.shake_camera()
	var items_to_remove = items.slice(start, end)
	
	if start > 0 and end < items.size():
		var group = split_group(start, end)
		group.state = FollowGroup.State.WAITING
		if group.prev_group and group.first_item().frame == group.prev_group.last_item().frame:
			GlobalTimer.create_async(func(): group.state = State.BACKWARDS, 0.5)
	else:
		print("NOOOOO")
		
	for follow in items_to_remove:
		follow.kill_ball()
		items.erase(follow)
