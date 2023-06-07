extends Node2D

signal collided(ball: Ball, collider, normal)

var ShootingBallScene = preload("res://ShootingBall.tscn")

var shooting_ball: ShootingBall
var shooting_direction: Vector2

@onready var ray_cast_2d: RayCast2D = $Toad/RayCast2D
@onready var polygon_2d: Polygon2D = $Toad/Polygon2D
@onready var toad = $Toad
@onready var spawn_point = $Toad/SpawnPoint
@onready var animation_player = $Toad/AnimationPlayer
@onready var shooting_sound = $ShootingSound


const color_dict = {
	0: Color8(28,105,253, 100),
	1: Color8(0, 156, 76, 100),
	2: Color8(255,193,2, 100),
	3: Color8(216,42,87, 100)
}


func _ready():
	spawn_shooting_ball()
	
	ray_cast_2d.collide_with_areas = true
	


func _process(delta):
#	shooting_direction = global_position.direction_to(get_global_mouse_position()).normalized()
	shooting_direction = Vector2.UP
	ray_cast_2d.target_position = shooting_direction * 4000
	var collision_point =  ray_cast_2d.get_collision_point()
	var point_position = collision_point if ray_cast_2d.is_colliding() else shooting_direction * 4000
	print(ray_cast_2d.position)

#	var mouse_rotation = Vector2.UP.angle_to(point_position)
	var mouse_rotation = Vector2.UP.angle_to(get_local_mouse_position().normalized())
	
	
	
	var local_point_position = to_local(point_position)
	polygon_2d.polygon = [Vector2(0, -local_point_position.length() - ray_cast_2d.position.y), Vector2(-30, 0), Vector2(30, 0)]
#	polygon_2d.rotation = mouse_rotation
	toad.rotation = mouse_rotation
	if shooting_ball:
		shooting_ball.global_position = spawn_point.global_position	
		polygon_2d.color = color_dict[shooting_ball.ball.frame]
		
	

func _input(event):
	if shooting_ball == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT :
			shooting_ball.shoot(shooting_direction)
			shooting_ball = null
			GlobalTimer.create_async(spawn_shooting_ball, 0.2)
			animation_player.play("shoot")
			shooting_sound.play()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			shooting_ball.change_color()

func spawn_shooting_ball():
	shooting_ball = ShootingBallScene.instantiate()
	spawn_point.add_child(shooting_ball)
	ray_cast_2d.add_exception(shooting_ball.ball)
	shooting_ball.collided.connect(_on_ball_collided)

func _on_ball_collided(ball, area, normal):
	collided.emit(ball, area, normal)
