extends Area2D

signal returned
signal collided(ball: Ball)

enum State { SHOOTING, RETURNING, IDLE }

var state = State.IDLE

@onready var sprite = $BallSprite

var velocity := Vector2.ZERO

var frame = null
var origin

func _ready():
	sprite.hide()

func shoot():
	if state != State.IDLE:
		return
	frame = null
	sprite.hide()
	area_entered.connect(_on_area_entered)
	velocity.y = -Globals.TONGUE_SPEED
	state = State.SHOOTING

	

func _physics_process(delta):

	if position.y < -1500:
		state = State.RETURNING
	elif position.y > 0:
		returned.emit()
		state = State.IDLE
		
	match state:
		State.SHOOTING:
			velocity.y = -Globals.TONGUE_SPEED
		State.RETURNING:
			velocity.y = Globals.TONGUE_SPEED
		State.IDLE:
			velocity = Vector2.ZERO
			position = Vector2.ZERO
			
	position += velocity * delta
	

func _on_area_entered(area):
	if area is Ball and state == State.SHOOTING:
		collided.emit(area)
		sprite.position = to_local(area.global_position)
		var tween = create_tween()
		tween.tween_property(sprite, 'position', Vector2.ZERO, 0.1)
		area_entered.disconnect(_on_area_entered)
		frame = area.frame
		sprite.frame = area.frame
		sprite.show()
		velocity.y = Globals.TONGUE_SPEED
		state = State.RETURNING
