class_name FollowGroup

enum State {
	FORWARDS, WAITING, RUSHING_BACKWARDS
}

var prev_group: FollowGroup
var next_group: FollowGroup

var manager: GroupManager
var path_2d: Path2D
var is_removed = false
var state = State.WAITING
var items: Array[FollowingBall]
var global_progress = 0
var current_speed: float = Globals.MAX_FORWARDS_SPEED

func _init(_manager: GroupManager):
	manager = _manager

func set_items(_items: Array[FollowingBall]) -> void:
	items.assign(_items)
	global_progress = first_item().current_progress
	_update_items_index_and_group()
	

func insert_item(item: FollowingBall, index = null):
	if index == null:
		index = items.size()

	items.insert(index, item)
	_update_items_index_and_group()		
	
	# if adding at the beginning, don't push others (actually, move everything back)
	if index == 0:
		global_progress -= Globals.BALL_WIDTH

func set_removed():
	items.clear()
	is_removed = true

var curve_time: float = 0.0
var last_speed = current_speed

func physics_process(delta):
	assert(!is_removed, "Probably still the first group, def a bug")
	# Go forwards if the only group
	if !next_group and !prev_group:
		state = State.FORWARDS
				
	if next_group and last_item().current_progress >= next_group.first_item().current_progress - Globals.BALL_WIDTH:
		_on_next_group_collision()
		Window
	if Globals.force_backwards:
		_spring(-Globals.MAX_FORWARDS_SPEED * 2, delta)
		return
		
	match state:
		State.FORWARDS:
			if Globals.force_waiting:
				current_speed -= Globals.MAX_FORWARDS_SPEED * 2 * delta
				current_speed = max(current_speed, 0)
				global_progress += current_speed * delta
			else:
				_spring(Globals.MAX_FORWARDS_SPEED, delta)
		
		State.RUSHING_BACKWARDS:
			current_speed -= Globals.BACKWARDS_ACCELERATION * delta
			current_speed = max(current_speed, -Globals.MAX_BACKWARDS_SPEED)
			global_progress += current_speed * delta

		State.WAITING:
			# if being pushed back
			if current_speed < 0:
				_spring(0, delta)

func first_item() -> FollowingBall:
	return items.front()
	
func last_item() -> FollowingBall:
	return items.back()
	
	
func rush_backwards_if_needed(delay = false):
	if delay:
		await manager.get_tree().create_timer(Globals.GOING_BACKWARDS_DELAY).timeout
	if is_removed:
		return
	if _should_rush_backwards():
		state = State.RUSHING_BACKWARDS
	# if currently rushing but shouldn't anymore (e.g. a ball got inbetween)
	elif state == State.RUSHING_BACKWARDS:
			state = State.WAITING
		

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
		
	var items_to_explode: Array[FollowingBall] = items.slice(start, end)
		
	if items_to_explode.any(func(item): return !item.is_ready_for_checking):
		return

	if items_to_explode.size() >= Globals.MIN_CONSECUTIVE_MATCH:
		if items_to_explode.any(func (item): return item.ball.variant == Ball.Variants.EXPLOSIVE):
			start = max(0, start - 5)
			end = min(items.size(), end + 5)
		elif items_to_explode.any(func (item): return item.ball.variant == Ball.Variants.PAUSE):
			Globals.force_waiting = true
			manager.get_tree().create_timer(5).timeout.connect(func(): Globals.force_waiting = false)
		elif items_to_explode.any(func (item): return item.ball.variant == Ball.Variants.BACKWARDS):
			Globals.force_backwards = true
			manager.get_tree().create_timer(5).timeout.connect(func(): Globals.force_backwards = false)
			
		explode_balls(start, end)
		


func explode_balls(start, end):
	var items_to_explode: Array[FollowingBall] = items.slice(start, end)
	Events.balls_exploding.emit(items_to_explode)

	for follow in items_to_explode:
		items.erase(follow)
		follow.kill_ball()
	_update_items_index_and_group()
	
	if items.is_empty():
		manager.remove_group(self)
		
	
	if start > 0 and start < items.size():
		manager.split_group(self, start)
		
	if start == 0:
		# offset progress to avoid the whole group moving back
		global_progress += items_to_explode.size() * Globals.BALL_WIDTH
		
	for group in [self, next_group]:
		if group and !group.is_removed:
			group.rush_backwards_if_needed(true)
			
func _on_next_group_collision():
	current_speed += next_group.current_speed	
	var item_to_check_from = last_item()
	manager.merge_groups(self, next_group)
	check_for_matches_from_item(item_to_check_from, true)
	
func _should_rush_backwards():
	return prev_group and first_item().frame == prev_group.last_item().frame
	
func _spring(target_speed, delta):
	var displacement = target_speed - current_speed  # Displacement from the resting position
	var acceleration = Globals.SPRING_CONSTANT * displacement  # Hooke's law
	current_speed = clampf(current_speed + acceleration * delta, -Globals.MAX_BACKWARDS_SPEED, target_speed)
	global_progress += current_speed * delta
	
func _update_items_index_and_group():
	for i in items.size():
		var item = items[i]
		item.index = i
		item.group = self
