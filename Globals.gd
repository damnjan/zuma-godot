extends Node

const BALL_WIDTH := 92.0

const FORWARDS_SPEED := 100.0

const BACKWARDS_SPEED := 1500.0

const SHOOTING_SPEED = 60.0

const MIN_CONSECUTIVE_MATCH = 3

func shake_camera():
	var first_node = get_tree().root.get_node("Node2D")
	first_node.get_node('PoppingSound').play()
	first_node.get_node("Shaker").start()

func play_merge_sound():
	get_tree().root.get_node("Node2D").get_node("MergeSound").play()
