extends Node

class_name GroupManager

@onready var path_2d = $"../Path2D"


var groups: Array[FollowGroup]

var _last_removed_group: FollowGroup # prevents random crashes ¯\_(ツ)_/¯

func _physics_process(delta):
	for group in groups:
		group.physics_process(delta)
		
func create_first_group() -> FollowGroup:
	assert(groups.is_empty())
	var group = FollowGroup.new(path_2d)
	_insert_group(group, 0)	
	return group
		
	
func create_group_after(group: FollowGroup) -> FollowGroup:
	var index = groups.find(group)
	assert(index >= 0)
	var new_group = FollowGroup.new(path_2d)
	_insert_group(new_group, index + 1)
	return new_group

func remove_group(group: FollowGroup):
	groups.erase(group)
	_last_removed_group = group	
	_update_refs()
	

func _insert_group(group: FollowGroup, index: int):
	groups.insert(index, group)
	_update_refs()

func _update_refs():
	var size = groups.size()
	for i in size:
		var group = groups[i]
		group.manager = self
		group.prev_group = groups[i - 1] if i > 0 else null
		group.next_group = groups[i + 1] if i < size - 1 else null
