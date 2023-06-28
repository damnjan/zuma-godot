extends Node2D

signal shooting_ball_collided(ball: Ball, collider, normal)

enum Modes { NORMAL, TONGUE }

@export var mode = Modes.NORMAL

var ShootingBallScene = preload("res://ball_shooter/ShootingBall.tscn")

var shooting_ball: ShootingBall
const shooting_direction = Vector2.UP

@onready var polygon_2d: Polygon2D = $Toad/Polygon2D
@onready var toad = $Toad
@onready var spawn_point = $Toad/SpawnPoint
@onready var animation_player = $Toad/AnimationPlayer
@onready var tongue = $Toad/TongueMask/Tongue
@onready var group_manager = $"../GroupManager"

func _ready():
	if mode == Modes.NORMAL:
		spawn_shooting_ball()
	tongue.returned.connect(_on_tongue_returned)
	tongue.collided.connect(_on_tongue_collided)
	
func ray_to_ball_intersection(ray_origin: Vector2, ray_direction: Vector2):
	var closest_intersection = null
	var closest_distance = INF
	var ball_radius = Globals.BALL_WIDTH / 2  # Assuming you have a property for the ball's radius
	for ball in get_tree().get_nodes_in_group('visible_balls'):
		var ball_position: Vector2 = ball.global_position
		var origin_to_ball: Vector2 = ball_position - ray_origin
		# Projection of the ball's position onto the ray direction
		var projection_length = origin_to_ball.dot(ray_direction)
		if projection_length < 0:
			continue
		# Closest point on the ray to the center of the circle
		var closest_point = ray_origin + ray_direction * projection_length
		var distance_to_ball_center = closest_point.distance_to(ball_position)
		if distance_to_ball_center < ball_radius * 2:
			# The ray intersects the ball.
			# Distance from the closest point on the line to the intersection
			var distance_to_intersection = sqrt(pow(ball_radius * 2, 2) - pow(distance_to_ball_center,2 ))
			var intersection_point = closest_point - ray_direction* distance_to_intersection
			var distance = ray_origin.distance_to(intersection_point)
			if distance < closest_distance:
				closest_distance = distance
				closest_intersection = intersection_point
	return closest_intersection

func _physics_process(_delta):
	var mouse_rotation = Vector2.UP.angle_to(get_local_mouse_position())
	var collision_point =  ray_to_ball_intersection(global_position, get_local_mouse_position().normalized())
	var point_position = collision_point if collision_point else shooting_direction * 4000
	var polygon_width = Globals.BALL_WIDTH
	var local_point_position = to_local(point_position)
	if mode == Modes.NORMAL:
		polygon_2d.visible = !!shooting_ball
	polygon_2d.polygon = [Vector2(0, -local_point_position.length() - polygon_2d.position.y), Vector2(-polygon_width/2, 0), Vector2(polygon_width/2, 0)]
	toad.rotation = mouse_rotation
	if shooting_ball:
		shooting_ball.global_position = spawn_point.global_position
		polygon_2d.color = Globals.color_dict[shooting_ball.ball.frame] if Globals.color_dict.has(shooting_ball.ball.frame) else Color(1,1,1,0.5)
	else:
		polygon_2d.color = Color(1,1,1,0.5)


func _input(event):
	if OS.is_debug_build():
		var keys = [KEY_1, KEY_2, KEY_3, KEY_4]
		for i in keys.size():
			if Input.is_key_pressed(keys[i]) and shooting_ball:
				shooting_ball.ball.frame = i
	
	if event.is_action_pressed("shoot") and shooting_ball:
		var glob_pos = shooting_ball.global_position
		var glob_rot = shooting_ball.global_rotation
		spawn_point.remove_child(shooting_ball)
		get_tree().root.add_child(shooting_ball)
		shooting_ball.global_scale = Vector2.ONE
		shooting_ball.global_position = glob_pos
		shooting_ball.global_rotation = glob_rot
		shooting_ball.shoot(get_local_mouse_position().normalized())
		animation_player.play("shoot")
		AudioManager.play(AudioManager.shooting_sound, shooting_ball.global_position)
		shooting_ball = null		
		if mode == Modes.NORMAL:
			get_tree().create_timer(0.2).timeout.connect(spawn_shooting_ball)
	elif event.is_action_pressed("tongue") and !shooting_ball:
		if mode == Modes.TONGUE:
			polygon_2d.hide()
			tongue.shoot()
		elif mode == Modes.NORMAL:
			shooting_ball.change_color()



func spawn_shooting_ball():
	shooting_ball = ShootingBallScene.instantiate()
	spawn_point.add_child(shooting_ball)
	shooting_ball.global_scale = Vector2.ONE
	
func _on_tongue_returned():
	polygon_2d.show()
	if tongue.frame != null:
		spawn_shooting_ball()
		shooting_ball.ball.frame = tongue.frame
		
func _on_tongue_collided(follow):
	assert(follow is FollowingBall, "Ball should be a FollowingBall")
	follow.remove_self()
