extends Area2D

func _on_body_entered(body):
    print(body.name + " entered the kill zone " + str(get_instance_id()) + " " +  str(body.state) + " != " + str(body.State.DEAD))
    if body.has_method("kill"):
        if body.state == body.State.DEAD:
            return
        await body.kill()
