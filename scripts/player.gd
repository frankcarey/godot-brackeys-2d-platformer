extends CharacterBody2D
# Make this into a type so we can reliably call it

# This signal is emitted when the player dies.
# It can be connected to other nodes to handle the death event.
signal player_died(player)

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const ACCEL = 1000. # this accelerates to about full after 4 squares.
const JUMP_BOOST_MULT = -.4 # this approximately doubles the jump height with 130 speed.
const DRAG = 700.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var hurt_sound: AudioStream
@export var jump_sound: AudioStream
@export var drop_sound: AudioStream

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var restart_timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

enum State {
    DEAD = 0,
    IDLE = 1,
}
var state: State


func _ready():
    state = State.IDLE

func spawn(pos = Vector2(0, 0)):
    print("spawning player")

    process_mode = PROCESS_MODE_INHERIT
    collision_shape_2d.disabled = false
    position = pos
    velocity = Vector2.ZERO
    velocity.y = 0
    velocity.x = 0
    animation_player.stop()

    await get_tree().process_frame
    position.y = position.y - 0.1
    print("back to IDLE")
    state = State.IDLE


func kill():
    if state == State.DEAD:
        return
    state = State.DEAD
    await get_tree().process_frame

    animation_player.play("hurt")
    animation_player.speed_scale = 4

    audio_stream_player_2d.stream = hurt_sound
    audio_stream_player_2d.volume_db = 0 # full volume
    audio_stream_player_2d.play()
    collision_shape_2d.disabled = true

    print("you died")
    Engine.time_scale = 0.25
    restart_timer.start()

func _on_timer_timeout():
    animation_player.speed_scale = 1
    Engine.time_scale = 1
    animation_player.stop()
    process_mode = PROCESS_MODE_DISABLED
    player_died.emit(self)

func handle_input():
    if Input.is_action_just_pressed("jump"):
        if Input.is_action_pressed("ui_down"):
            drop()
        else:
            jump()


func jump():
    if is_on_floor():
        audio_stream_player_2d.stream = jump_sound
        audio_stream_player_2d.volume_db = -8 # lower volume
        audio_stream_player_2d.play()
        velocity.y = JUMP_VELOCITY + (abs(velocity.x) * JUMP_BOOST_MULT)

func drop():
    if is_on_floor():
        audio_stream_player_2d.stream = drop_sound
        audio_stream_player_2d.volume_db = -8 # lower volume
        audio_stream_player_2d.play()
        position.y += 1 # causes player to drop through one way colliders.

func get_floor_material():
    var _floor = get_last_slide_collision()
    if is_on_floor() and _floor != null:
        var hit_object = _floor.get_collider()
        if hit_object is TileMap:
            var rid = _floor.get_collider_rid()
            var coord: Vector2 = hit_object.get_coords_for_body_rid(rid)
            var layer: int = hit_object.get_layer_for_body_rid(rid)
            var tiledata: TileData = hit_object.get_cell_tile_data(layer, coord)
            var mat = tiledata.get_custom_data("material")
            return mat
    return null


func _physics_process(delta):

    handle_input()

    var direction = Input.get_axis("move_left", "move_right")
    # Add the gravity.
    if is_on_floor():
        if direction == 0:
            animated_sprite_2d.play("idle")
        else:
            animated_sprite_2d.play("run")
    else:
        animated_sprite_2d.play("jump")
        match state:
            State.DEAD:
                velocity.y += gravity * delta * 3
            _:
                velocity.y += gravity * delta

    # HANDLE MOVEMENT INPUT (LEFT/RIGHT)
    if direction > 0:
        animated_sprite_2d.flip_h = false
    elif direction < 0:
        animated_sprite_2d.flip_h = true



    var stickiness = 0.8
    if not is_on_floor():
        stickiness = 0.3
    else:
        var tile_material = get_floor_material()
        if tile_material == "ice":
            stickiness = 0.1

    # direction is between -1 and +1 based on the controller value.
    if direction:
        var speed_limiter = abs(direction)**4 + SPEED
        velocity.x = clampf(velocity.x + (direction * ACCEL * delta * stickiness), -speed_limiter, speed_limiter)
    else:
        velocity.x = move_toward(velocity.x, 0, DRAG * delta * stickiness)

    move_and_slide()
