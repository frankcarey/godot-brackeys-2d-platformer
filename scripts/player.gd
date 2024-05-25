extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -200.0
const ACCEL = 1000. # this accelerates to about full after 4 squares.
const JUMP_BOOST_MULT = -1. # this approximately doubles the jump height with 130 speed.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var hurt_sound: AudioStream
@export var jump_sound: AudioStream

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var restart_timer = $Timer

enum State {
	DEAD,
	ALIVE
}
var state: State

func _ready():
	state = State.ALIVE

func kill():
	state = State.DEAD
	audio_stream_player_2d.stream = hurt_sound
	audio_stream_player_2d.play()
	print("you died")
	Engine.time_scale = 0.25
	$CollisionShape2D.queue_free()
	restart_timer.start()
	

func _physics_process(delta):
	# Add the gravity.
	
	if state == State.DEAD:
		velocity.y += gravity * delta * 4
		move_and_slide()
		return
	elif not is_on_floor():
		velocity.y += gravity * delta


	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Drop below one-way platforms.
		if Input.is_action_pressed("ui_down") and is_on_floor():
			position.y += 1
		else:
			velocity.y = JUMP_VELOCITY + (abs(velocity.x) * JUMP_BOOST_MULT)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	

func _on_timer_timeout():
	# Restarts the game.
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
