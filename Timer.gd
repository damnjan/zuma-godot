extends Node


func create(seconds):
	return get_tree().create_timer(seconds)

func create_async(callback: Callable, seconds: float):
	var timer = get_tree().create_timer(seconds)
	timer.connect("timeout", callback)
