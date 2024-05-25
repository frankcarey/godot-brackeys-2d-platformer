extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -200.0
const ACCEL = 1000. # this accelerates to about full after 4 squares.
const JUMP_BOOST_MULT = -1. # this approximately doubles the jump height with 130 speed.
const DRAG = 700.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var hurt_sound: AudioStream
@export var jump_sound: AudioStream
@export var drop_sound: AudioStream

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var restart_timer = $Timer
@onready var animation_player = $AnimationPlayer

enum State {
	DEAD,
	IDLE,
	JUMP,
	DROP
}
var state: State

func _ready():
	state = State.IDLE

func kill():
	state = State.DEAD
	
	animation_player.play("hurt")
	animation_player.speed_scale = 4
	
	audio_stream_player_2d.stream = hurt_sound
	audio_stream_player_2d.volume_db = 0 # full volume
	audio_stream_player_2d.play()
	
	print("you died")
	Engine.time_scale = 0.25
	$CollisionShape2D.queue_free()
	restart_timer.start()

func _process(delta):	
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("ui_down"):
			drop()
		else:
			jump()
			

func jump():
	if is_on_floor():
		state = State.JUMP
		audio_stream_player_2d.stream = jump_sound
		audio_stream_player_2d.volume_db = -8 # lower volume
		audio_stream_player_2d.play()

func drop():
	if is_on_floor():
		state = State.DROP
		audio_stream_player_2d.stream = drop_sound
		audio_stream_player_2d.volume_db = -8 # lower volume
		audio_stream_player_2d.play()

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	match state:
		State.DROP:
			position.y += 1
			state = State.IDLE
		State.JUMP:
			velocity.y = JUMP_VELOCITY + (abs(velocity.x) * JUMP_BOOST_MULT)
			state = State.IDLE
		State.DEAD:
			velocity.y += gravity * delta * 3
	
	
	# HANDLE MOVEMENT INPUT (LEFT/RIGHT)
	var direction = Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")
	
	if direction:
		var speed_limiter = abs(direction)**2 + SPEED
		velocity.x = clampf(velocity.x + (direction * ACCEL * delta), -speed_limiter, speed_limiter)
	else:
		velocity.x = move_toward(velocity.x, 0, DRAG * delta)

	move_and_slide()
	

func _on_timer_timeout():
	# Restarts the game.
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
