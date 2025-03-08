extends Area2D

func _on_body_entered(body):
    print(body.name + " entered the kill zone")
    if body.has_method("kill"):
        body.kill()
