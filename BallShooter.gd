extends Node2D

signal shooting_ball_collided(ball: Ball, collider, normal)

enum Modes { NORMAL, TONGUE }

@export var mode = Modes.NORMAL

var ShootingBallScene = preload("res://ShootingBall.tscn")

var shooting_ball: ShootingBall
const shooting_direction = Vector2.UP

@onready var polygon_2d: Polygon2D = $Toad/Polygon2D
@onready var toad = $Toad
@onready var spawn_point = $Toad/SpawnPoint
@onready var animation_player = $Toad/AnimationPlayer
@onready var tongue = $Toad/TongueMask/Tongue

func _ready():
	if mode == Modes.NORMAL:
		spawn_shooting_ball()
	tongue.returned.connect(_on_tongue_returned)
	tongue.collided.connect(_on_tongue_collided)
	
func ray_to_ball_intersection(ray_origin: Vector2, ray_direction: Vector2):
	var closest = {
		"intersection": null,
		"distance": INF
	}
	var ball_radius = Globals.BALL_WIDTH / 2  # Assuming you have a property for the ball's radius
	
	Globals.for_each_visible_ball(func (ball):
		var ball_position: Vector2 = ball.global_position
		var origin_to_ball: Vector2 = ball_position - ray_origin
		
		# Projection of the ball's position onto the ray direction
		var projection_length = origin_to_ball.dot(ray_direction)
			
		if projection_length < 0:
			return

		# Closest point on the ray to the center of the circle
		var closest_point = ray_origin + ray_direction * projection_length

		var distance_to_ball_center = closest_point.distance_to(ball_position)

		if distance_to_ball_center < ball_radius:
			# The ray intersects the ball.
			# Distance from the closest point on the line to the intersection
			var distance_to_intersection = sqrt(ball_radius * ball_radius - distance_to_ball_center * distance_to_ball_center)
			
			var intersection_point = closest_point - ray_direction* distance_to_intersection
			var distance = ray_origin.distance_to(intersection_point)

			if distance < closest.distance:
				closest.distance = distance
				closest.intersection = intersection_point
	)

	return closest.intersection

func _physics_process(_delta):
	var mouse_rotation = Vector2.UP.angle_to(get_local_mouse_position().normalized())	
	var collision_point =  ray_to_ball_intersection(global_position, get_local_mouse_position().normalized())
	
	var point_position = collision_point if collision_point else shooting_direction * 4000
	var local_point_position = to_local(point_position)
	if mode == Modes.NORMAL:
		polygon_2d.visible = !!shooting_ball
	polygon_2d.polygon = [Vector2(0, -local_point_position.length() - polygon_2d.position.y), Vector2(-30, 0), Vector2(30, 0)]
	toad.rotation = mouse_rotation
	if shooting_ball:
		shooting_ball.global_position = spawn_point.global_position	
		polygon_2d.color = Globals.color_dict[shooting_ball.ball.frame] if Globals.color_dict.has(shooting_ball.ball.frame) else Color(1,1,1,0.5)
	else:
		polygon_2d.color = Color(1,1,1,0.5)


func _input(event):
	if event.is_action_pressed("shoot") and shooting_ball:
		var glob = shooting_ball.global_position
		spawn_point.remove_child(shooting_ball)
		get_tree().root.add_child(shooting_ball)
		shooting_ball.global_scale = Vector2.ONE
		shooting_ball.global_position = glob
		shooting_ball.shoot(get_local_mouse_position().normalized())
		shooting_ball = null
		animation_player.play("shoot")
		AudioManager.play(AudioManager.shooting_sound)
		if mode == Modes.NORMAL:
			GlobalTimer.create_async(spawn_shooting_ball, 0.2)
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
