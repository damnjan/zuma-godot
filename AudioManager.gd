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
	play(music)


func play(player: AudioStreamPlayer):
	if muted:
		return
	player.play()
