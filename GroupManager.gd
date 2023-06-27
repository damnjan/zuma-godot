extends Path2D

class_name GroupManager

var groups: Array[FollowGroup]

var _last_removed_group: FollowGroup # prevents random crashes ¯\_(ツ)_/¯

func _init():
	Events.shooting_ball_collided.connect(_on_shooting_ball_collided)

func _physics_process(delta):
	for group in groups:
		group.physics_process(delta)

func _draw():
	draw_polyline(curve.get_baked_points(), Color.from_string('#21220f', Color.BLUE), 20, true)
		
func create_first_group(balls: Array[FollowingBall]) -> FollowGroup:
	assert(groups.is_empty())
	var group = FollowGroup.new(self)
	group.set_items(balls)
	for ball in balls:
		add_child.call_deferred(ball)
	_insert_group(group, 0)	
	return group
	
func split_group(group: FollowGroup, index: int):
	assert(index > 0 and index < group.items.size(), "Invalid index")
	var new_group_items = group.items.slice(index)
	
	group.set_items(group.items.slice(0, index))

	var new_group = _create_group_after(group)
	new_group.set_items(new_group_items)
	return new_group
	
func merge_groups(group: FollowGroup, next_group: FollowGroup):
	group.set_items(group.items + next_group.items)
	remove_group(next_group)
	AudioManager.play(AudioManager.merge_sound)
		

func remove_group(group: FollowGroup):
	group.set_removed()
	groups.erase(group)
	_last_removed_group = group	
	_update_refs()

func _create_group_after(group: FollowGroup) -> FollowGroup:
	var index = groups.find(group)
	assert(index >= 0)
	var new_group = FollowGroup.new(self)
	_insert_group(new_group, index + 1)
	return new_group
	
func _insert_group(group: FollowGroup, index: int):
	groups.insert(index, group)
	_update_refs()

func _update_refs():
	var size = groups.size()
	for i in size:
		var group = groups[i]
		group.prev_group = groups[i - 1] if i > 0 else null
		group.next_group = groups[i + 1] if i < size - 1 else null

func _on_shooting_ball_collided(ball: Ball, collided_follow: FollowingBall):
	var normal = (ball.global_position - collided_follow.global_position).normalized().rotated(-collided_follow.rotation)
	var group = collided_follow.group	
	var i = collided_follow.index
	var insert_index = i if normal.x < 0 else i + 1
	var follow = FollowingBall.new(ball.frame, ball.global_position, ball.global_rotation)
	group.insert_item(follow, insert_index)
	add_child(follow)
