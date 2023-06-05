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
	
	print("New group count ", new_group.items.size())
	
	new_group.global_progress = new_group.items[0].progress
		
	return new_group
		


func _check_for_matches():
	if not _follows_to_delete.is_empty():
		return
	for i in items.size():
		var consecutive = []
		var x = i
		while x < items.size() and items[x].ball.frame == items[i].ball.frame:
			consecutive.append(items[x])
			x += 1
		if consecutive.size() >= 3:
			_follows_to_delete.append_array(consecutive)
			Globals.shake_camera()
			
				
			var starting_index = x - consecutive.size()
			if starting_index > 0 and x < items.size():
				var group = split_group(starting_index, x)
				group.state = FollowGroup.State.WAITING
				
				
			for follow in consecutive:
				follow.kill_ball()
				items.erase(follow)
				_follows_to_delete.erase(follow)
			
			break

func add_item(item: FollowingBall, index):
#	item.ball.died.connect(_on_ball_died)
#	item.progress = items.size() * Globals.BALL_WIDTH
	if index != null:
		items.insert(index, item)
	else:
		items.append(item)
		index = items.size() - 1
	item.progress = index * Globals.BALL_WIDTH + global_progress

func change_state(next_state: State):
	state = next_state
	
func remove():
	if prev_group:
		prev_group.next_group = next_group
	if next_group:
		next_group.prev_group = prev_group
		
#	free()
	

func merge_next_group():
	items.append_array(next_group.items)
	print("Next group before ", next_group)
	next_group.remove()


func physics_process(delta):
	_check_for_matches()
	if prev_group and first_item().ball.frame == prev_group.last_item().ball.frame:
		state = State.BACKWARDS
	match state:
		State.FORWARDS:
			global_progress += Globals.FORWARDS_SPEED * delta
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1)
#			print("Next group", next_group)
			if next_group != null and last_item().progress >= next_group.first_item().progress - Globals.BALL_WIDTH:
				print("Merging next group")
				merge_next_group()
		
		State.BACKWARDS:
			for item in items:
				item.progress -= Globals.BACKWARDS_SPEED * delta
			if prev_group != null and first_item().progress <= prev_group.last_item().progress and prev_group.state != State.FORWARDS:
				prev_group.merge_next_group()
				
		State.WAITING:
			for i in items.size():
				var new_progress = global_progress + i * Globals.BALL_WIDTH
				items[i].progress = lerpf(items[i].progress, new_progress, 0.1)
	
	

func first_item() -> FollowingBall:
	return items.front()
	
func last_item() -> FollowingBall:
	return items.back()
	
