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
var current_speed: float = Globals.MAX_FORWARDS_SPEED
var is_inserting = false # a ball is currently being inserted (added but not ready)

var _balls_being_inserted = []

# a and b are indexes of first and last marble that explodes
func split_group(index):
	assert(index > 0 and index < items.size(), "Invalid index")
	var new_group = FollowGroup.new()
	new_group.prev_group = self
	new_group.next_group = next_group
	new_group.items = items.slice(index)	
	new_group.update_items_index_and_group()
	
	items = items.slice(0, index)
	update_items_index_and_group()
	
	if next_group:
		next_group.prev_group = new_group
		
	next_group = new_group
	new_group.global_progress = new_group.items[0].progress
	new_group.state = State.WAITING
	return new_group



func add_item(item: FollowingBall, index, instant_ready = false):
	Globals.combo = 0
	if index == null:
		index = items.size()

	items.insert(index, item)
	update_items_index_and_group()	
	
	# if adding at the beginning, don't push others (actually, move everything back)
	if index == 0 and !instant_ready:
		global_progress -= Globals.BALL_WIDTH
		
	item.progress = index * Globals.BALL_WIDTH + global_progress
	
	if instant_ready:
		item.is_ready_for_checking = true
	else:
		assert(!_balls_being_inserted.has(item), "Item already in array, this is a bug")
		_balls_being_inserted.append(item)
		is_inserting = true
		## TODO: This is ugly, find a better way
		item.ready_for_checking.connect(func(): 
			assert(_balls_being_inserted.has(item), "Item doesn't exist in array, this is a bug")			
			_balls_being_inserted.erase(item)
			item.group.check_for_matches_from_item(item)
			if _balls_being_inserted.is_empty():
				is_inserting = false
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
	var item_to_check_from = last_item()
	items.append_array(next_group.items)
	update_items_index_and_group()
	current_speed += next_group.current_speed
	next_group.remove()
	check_for_matches_from_item(item_to_check_from, true)
	AudioManager.play(AudioManager.merge_sound)

var curve_time: float = 0.0
var last_speed = current_speed

func physics_process(delta):
	if is_removed:
		print("this is removed , no point")
		return
	match state:
		State.FORWARDS:
			
			var displacement = Globals.MAX_FORWARDS_SPEED - current_speed  # Displacement from the resting position
			var acceleration = Globals.SPRING_CONSTANT * displacement  # Hooke's law

			current_speed = clampf(current_speed + acceleration * delta, -Globals.MAX_BACKWARDS_SPEED, Globals.MAX_FORWARDS_SPEED)
			global_progress += current_speed * delta
			_update_items_progress()
			
		State.BACKWARDS:
			current_speed -= Globals.BACKWARDS_ACCELERATION * delta
			current_speed = max(current_speed, -Globals.MAX_BACKWARDS_SPEED)
			global_progress += current_speed * delta
			_update_items_progress()

		State.WAITING:
			# if being pushed back
			if current_speed < 0:
				# old behavior:
#				current_speed += Globals.MAX_FORWARDS_SPEED
#				global_progress += current_speed * delta
				# new behavior:
				var displacement = 0 - current_speed  # Displacement from the resting position
				var acceleration = Globals.SPRING_CONSTANT * displacement  # Hooke's law
				current_speed = clampf(current_speed + acceleration * delta, -Globals.MAX_BACKWARDS_SPEED, 0)
				global_progress += current_speed * delta
			_update_items_progress()
				
	if prev_group != null and first_item().progress <= prev_group.last_item().progress + Globals.BALL_WIDTH and prev_group.state != State.FORWARDS:
		prev_group.merge_next_group()
				
	elif next_group != null and last_item().progress >= next_group.first_item().progress - Globals.BALL_WIDTH:
		merge_next_group()
	

func first_item() -> FollowingBall:
	return items.front()
	
func last_item() -> FollowingBall:
	return items.back()
	
	
func rush_backwards_if_needed(delay = false):
	if _should_rush_backwards():
		if delay:
			GlobalTimer.create_async(rush_backwards, Globals.GOING_BACKWARDS_DELAY)
		else:
			rush_backwards()
	
func rush_backwards():
	state = State.BACKWARDS

func check_for_matches_from_item(item: FollowingBall, is_merge = false):
	if item.is_dying:
		print("Dying, skipping.")
		return
		
	for group in [self, next_group]:
		if group:
			group.rush_backwards_if_needed()
		
	var index = items.find(item)
	var start = index
	var end = index # end is non inclusive
	
	while start -1 >= 0 and items[start - 1].frame == items[index].frame:
		start -= 1
	while end < items.size() and items[end].frame == items[index].frame:
		end += 1
#	
	if is_merge and end == index + 1:
		# this means that two groups are merging, and one of them has consecutive balls but the other doesn't, so skip
		return
		
	var items_to_explode = items.slice(start, end)
		
	if items_to_explode.any(func(item): return !item.is_ready_for_checking):
			return

	if items_to_explode.size() >= Globals.MIN_CONSECUTIVE_MATCH:
#		for x in items_to_explode:
#			explode_balls([x])
		explode_balls(items_to_explode)
		


func explode_balls(items_to_explode: Array[FollowingBall]):
	Events.balls_exploding.emit(items_to_explode)
	var start = items.find(items_to_explode[0])

	for follow in items_to_explode:
		items.erase(follow)
		follow.kill_ball()
	
	if items.is_empty():
		print("Items empty ,removing")
		remove()
		
	
	if start > 0 and start < items.size():
		split_group(start)
		next_group.state = State.WAITING
		
	if start == 0:
		# offset progress to avoid the whole group moving back
		global_progress += items_to_explode.size() * Globals.BALL_WIDTH
		
	for group in [self, next_group]:
		if group and !group.is_removed:
			group.rush_backwards_if_needed(true)

func _update_items_progress():
	for i in items.size():	
		assert(is_instance_valid(items[i]), "AAAAAAA INVALID!!!!!11111")
		var new_progress = global_progress + i * Globals.BALL_WIDTH
		# when being hit from a group that moves backwards, don't interpolate because it looks weird
		if !is_inserting and state == State.FORWARDS and current_speed < 0:
			items[i].progress = new_progress
		else:
			items[i].progress = lerpf(items[i].progress, new_progress, Globals.PROGRESS_LERP_WEIGHT)
	
func _should_rush_backwards():
	return prev_group and first_item().frame == prev_group.last_item().frame
	
func update_items_index_and_group():
	for i in items.size():
		items[i].index = i
		items[i].group = self
