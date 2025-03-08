extends Node

@export var level_resource: PackedScene
@export var level: Node2D
@export var player: Node2D

@export var coins_gathered: Array[String] = []

@onready var last_spawn_location = Vector2(30, -100)

var score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    # Check that player is set.
    if player == null:
        print("Player is not set.")
        return
    else:
        player.connect("player_died", _on_player_died)
    restart_from_last_checkpoint()

func add_point():
    score += 1
    print(score)

func get_coins():
    # Get the game manager node from the scene tree
    var coins = get_tree().get_nodes_in_group("coins")
    print("coins: ", coins.size())
    for coin in coins:
        print(coin.name)
        if coin.name in coins_gathered:
            coin.queue_free()
            continue
        print(coin.name + " not in coins_gathered")
        coin.coin_collected.connect(_on_coin_collected)
        score += 1

func _on_coin_collected(coin: Node2D):
    print("Coin collected: ", coin.name)
    last_spawn_location = coin.global_position
    gather_coin(coin)

func gather_coin(coin: Node2D):
    # Check if the coin is already gathered
    if coin.name in coins_gathered:
        return

    # Add the coin to the list of gathered coins
    coins_gathered.append(coin.name)

    # Remove the coin from the scene
    coin.queue_free()

func _on_player_died(_p: Node2D):
    print("Player died")
    # Restart the game
    restart_from_last_checkpoint()

func restart_from_last_checkpoint():
    print("Restarting from last checkpoint")

    # Check if the level resource is valid.
    if level_resource == null:
        print("Level resource is not set.")
        return

    # Restarts the game.
    Engine.time_scale = 1.0

    var lv = level_resource.instantiate()
    # Delete the old set of bricks just in case.
    level.queue_free()
    # Add the new level as a child to the root node.
    await get_tree().root.call_deferred("add_child", lv)
    await get_tree().process_frame
    level = lv
    print("Level loaded")

    get_coins()

    player.spawn(last_spawn_location)
