extends Node

@export var level_resource: PackedScene
@export var level: Node2D
@export var player: Node2D
@export var timer_label: Label
@export var score_label: Label
@export var death_label: Label
@export var accept_dialog: AcceptDialog

@export var coins_gathered: Array[String] = []

@onready var last_spawn_location = Vector2(30, -100)

var init = false
var score = 0
var total_coins = 0
var deaths = 0
var callback: Callable
var is_paused = false
var start_time = Time.get_ticks_msec()

func pause(do_pause: bool):
    # Pause the game
    get_tree().paused = do_pause
    is_paused = do_pause

func get_level_time() -> float:
    # Get the time since the level started
    return (Time.get_ticks_msec() - start_time) / 1000.0


# Called when the node enters the scene tree for the first time.
func _ready():
    # Check that player is set.
    if player == null:
        print("Player is not set.")
        return
    else:
        player.connect("player_died", _on_player_died)

    #Show the start dialog
    show_dialog("Welcome to the game!",
        "Press OK to start the game.",
        "OK",
        _on_accept_dialog_start
    )

func _on_accept_dialog_start():
    restart_from_last_checkpoint()
    start_time = Time.get_ticks_msec()

func show_dialog(title: String, message: String, button_text: String, callback: Callable):
    # Show the dialog
    pause(true)
    accept_dialog.popup_centered()
    accept_dialog.confirmed.connect(_on_accept_dialog_confirmed)
    accept_dialog.get_ok_button().text = button_text
    accept_dialog.dialog_text = message
    accept_dialog.title = title
    accept_dialog.process_mode = PROCESS_MODE_WHEN_PAUSED
    self.callback = callback

func _on_accept_dialog_confirmed():
    # Hide the dialog
    accept_dialog.hide()
    # Disconnect the signal to avoid multiple connections
    accept_dialog.confirmed.disconnect(_on_accept_dialog_confirmed)
    pause(false)
    accept_dialog.process_mode = PROCESS_MODE_INHERIT
    if callback:
        # Call the callback function if provided
        callback.call()
    else:
        print("Dialog callback is null")

func _process(delta):
    if not init:
        restart_from_last_checkpoint()
        init = true
    if is_paused:
        return
    # Update the timer label in format "Time: 0.000s"
    timer_label.text = "Time: " + "%8.1f" % ((Time.get_ticks_msec() - start_time) / 1000.0) + "s"


func update_score():
    # Update the score label
    score_label.text = "Coins:" + str(score) + "/" + str(total_coins)

func add_point():
    score += 1
    # Update the score label
    update_score()

func get_coins():
    # Get the game manager node from the scene tree
    var coins = get_tree().get_nodes_in_group("coins")
    print("coins: ", coins.size())
    score = 0
    total_coins = 0
    for coin in coins:
        print(coin.name)
        total_coins += 1
        if coin.name in coins_gathered:
            coin.queue_free()
            score += 1
            continue
        print(coin.name + " not in coins_gathered")
        coin.coin_collected.connect(_on_coin_collected)
    # total_coins = 1 # For testing the end screen, set total coins to 1
    update_score()


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

    # Add a point to the score
    add_point()

    if score == total_coins:
        # Show the dialog

        show_dialog("All coins collected!", "All coins collected!\n\n" + \
            str(score) + "/" + str(total_coins) + " coins collected.\n\n" + \
            "Completed Time: " + "%8.1f" % get_level_time() + "s\n\n" + \
            "Deaths: " + str(deaths) + "\n\n" + \
            "Press Restart Level to continue.", "Restart Level",
        _on_accept_dialog_endscreen)
    else:
        # Update the score label
        update_score()

func _on_accept_dialog_endscreen():
    # Load the next level
    get_tree().reload_current_scene()

func _on_player_died(_p: Node2D):
    print("Player died")
    deaths += 1
    death_label.text = "Deaths: " + str(deaths)
    # Restart the game
    restart_from_last_checkpoint()

func restart_from_last_checkpoint():
    print("Restarting from last checkpoint")

    # Check if the level resource is valid.
    if level_resource == null:
        print("Level resource is not set.")
        return

    await player.spawn(last_spawn_location)

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
