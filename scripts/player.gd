extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -200.0
const ACCEL = 1000. # this accelerates to about full after 4 squares.
const JUMP_BOOST_MULT = -1. # this approximately doubles the jump height with 130 speed.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d = $AnimatedSprite2D

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
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
		velocity.x = clampf(velocity.x + (direction * ACCEL * delta), -SPEED, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
