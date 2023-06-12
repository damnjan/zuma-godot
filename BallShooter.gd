extends Node2D

signal shooting_ball_collided(ball: Ball, collider, normal)

var ShootingBallScene = preload("res://ShootingBall.tscn")

var shooting_ball: ShootingBall
const shooting_direction = Vector2.UP

@onready var ray_cast_2d: RayCast2D = $Toad/RayCast2D
@onready var polygon_2d: Polygon2D = $Toad/Polygon2D
@onready var toad = $Toad
@onready var spawn_point = $Toad/SpawnPoint
@onready var animation_player = $Toad/AnimationPlayer





func _ready():
	spawn_shooting_ball()
	ray_cast_2d.collide_with_areas = true
	ray_cast_2d.target_position = shooting_direction * 4000


func _process(delta):
	var collision_point =  ray_cast_2d.get_collision_point()
	var point_position = collision_point if ray_cast_2d.is_colliding() else ray_cast_2d.target_position
	var mouse_rotation = Vector2.UP.angle_to(get_local_mouse_position().normalized())
	var local_point_position = to_local(point_position)
	polygon_2d.polygon = [Vector2(0, -local_point_position.length() - ray_cast_2d.position.y), Vector2(-30, 0), Vector2(30, 0)]
	toad.rotation = mouse_rotation
	if shooting_ball:
		shooting_ball.global_position = spawn_point.global_position	
		polygon_2d.color = Globals.color_dict[shooting_ball.ball.frame] if Globals.color_dict.has(shooting_ball.ball.frame) else Color(1,1,1,0.5)
		

func _input(event):
	if shooting_ball == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT :
			var glob = shooting_ball.global_position
			spawn_point.remove_child(shooting_ball)
			get_tree().root.add_child(shooting_ball)
			shooting_ball.global_scale = Vector2.ONE
			shooting_ball.global_position = glob
			shooting_ball.shoot(get_local_mouse_position().normalized())
			shooting_ball = null
			GlobalTimer.create_async(spawn_shooting_ball, 0.2)
			animation_player.play("shoot")
			AudioManager.play(AudioManager.shooting_sound)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			shooting_ball.change_color()

func spawn_shooting_ball():
	shooting_ball = ShootingBallScene.instantiate()
	spawn_point.add_child(shooting_ball)
	shooting_ball.global_scale = Vector2.ONE
	ray_cast_2d.add_exception(shooting_ball.ball)