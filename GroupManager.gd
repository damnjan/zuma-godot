extends Node

var groups: Array[FollowGroup]

func insert_group(group: FollowGroup, index: int):
	groups.insert(index, group)
	update_refs()

func remove_group(group: FollowGroup):
	groups.erase(group)
	update_refs()

func update_refs():
	var size = groups.size()
	for i in size:
		var group = groups[i]
		group.group_index = i
		group.manager = self
		group.prev_group = groups[i - 1] if i > 0 else null
		group.next_group = groups[i + 1] if i < size - 1 else null
			