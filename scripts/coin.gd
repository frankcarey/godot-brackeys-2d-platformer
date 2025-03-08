extends Area2D
var game_manager: Node

signal coin_collected(coin)

@onready var coin_sound = $CoinSound
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
    add_to_group("coins")

func _on_body_entered(body):
    print(body.name + " entered the coin")
    animation_player.play("pickup")
    await animation_player.animation_finished
    coin_collected.emit(self)
