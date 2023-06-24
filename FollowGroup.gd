class_name FollowGroup

enum State {
	FORWARDS, WAITING, BACKWARDS
}

var prev_group: FollowGroup
var next_group: FollowGroup

var manager: GroupManager

var is_removed = false
var state = State.FORWARDS
var items: Array[FollowingBall]
var global_progress = 0
var current_speed: float = Globals.MAX_FORWARDS_SPEED
var is_inserting = false # a ball is currently being inserted (added but not ready)

var _balls_being_inserted = []
var group_index := -1

func _init(initial_items: Array[FollowingBall]):
	# keep active reference to groups because godot's garbage collector seems to have some weird bug
	# i know it makes no sense but after many hours of hunting for the bug, this is the only thing that works
#	Globals.all_groups.append(self)
	items = initial_items
	update_items_index_and_group()

func split_group(index: int):
	assert(index > 0 and index < items.size(), "Invalid index")
	var new_group = FollowGroup.new(items.slice(index))
	
	
	items = items.slice(0, index)
	update_items_index_and_group()

	manager.insert_group(new_group, group_index + 1)
	new_group.global_progress = new_group.first_item().current_progress
	new_group.state = State.WAITING
	return new_group
	

func insert_item(item: FollowingBall, index = null):
	if index == null:
		index = items.size()

	items.insert(index, item)
	update_items_index_and_group()	
	
	# if adding at the beginning, don't push others (actually, move everything back)
	if index == 0:
		global_progress -= Globals.BALL_WIDTH
		

	## TODO: This is ugly, find a better way
	if !item.is_ready_for_checking:
		assert(!_balls_being_inserted.has(item), "Item already in array, this is a bug")
		_balls_being_inserted.append(item)
		is_inserting = true
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
	items.clear()
	is_removed = true
	# if this was the first group
	if !prev_group and next_group:
		next_group.state = State.FORWARDS
	manager.remove_group(self)

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
	assert(!is_removed, "Probably still the first group, def a bug")
	assert(group_index >= 0)
				
	if next_group and last_item().current_progress >= next_group.first_item().current_progress - Globals.BALL_WIDTH:
		merge_next_group()
		
	match state:
		State.FORWARDS:
			
			var displacement = Globals.MAX_FORWARDS_SPEED - current_speed  # Displacement from the resting position
			var acceleration = Globals.SPRING_CONSTANT * displacement  # Hooke's law

			current_speed = clampf(current_speed + acceleration * delta, -Globals.MAX_BACKWARDS_SPEED, Globals.MAX_FORWARDS_SPEED)
			global_progress += current_speed * delta
		
		State.BACKWARDS:
			current_speed -= Globals.BACKWARDS_ACCELERATION * delta
			current_speed = max(current_speed, -Globals.MAX_BACKWARDS_SPEED)
			global_progress += current_speed * delta

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
	assert(items.has(item), "Item doesn't belong here anymore")
		
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
		explode_balls(items_to_explode)
		


func explode_balls(items_to_explode: Array[FollowingBall]):
	Events.balls_exploding.emit(items_to_explode)
	var start = items.find(items_to_explode[0])

	for follow in items_to_explode:
		items.erase(follow)
		follow.kill_ball()
	update_items_index_and_group()
	
	if items.is_empty():
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
	
func _should_rush_backwards():
	return prev_group and first_item().frame == prev_group.last_item().frame
	
func update_items_index_and_group():
	for i in items.size():
		var item = items[i]
		item.index = i
		item.group = self
