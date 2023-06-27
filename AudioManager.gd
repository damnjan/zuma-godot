extends Node2D

@export var muted = false
@export var music_while_debug = false

@onready var insert_sound = $InsertSound
@onready var popping_sound = $PoppingSound
@onready var merge_sound = $MergeSound
@onready var shooting_sound = $ShootingSound
@onready var music = $Music



func _ready():
	if OS.is_debug_build() and !music_while_debug:
		return
	music.play()


func play(player: AudioStreamPlayer2D, _position = null):
	if muted:
		return
	if _position == null:
		_position = get_viewport_rect().size / 2
	player.position = _position
	player.play()
