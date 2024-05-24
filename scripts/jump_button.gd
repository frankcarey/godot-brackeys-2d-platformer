extends Control

var is_pressed := false
var touch_idx = -1

@onready var texture_rect = $TextureRect


#if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY :
		#hide()
	#
	#if visibility_mode == Visibility_mode.WHEN_TOUCHED:
		#hide()

#func _(event: InputEvent) -> void:
	#if event is InputEventScreenTouch:
		#if get_global_rect().has_point(event.position):
			#is_pressed = event.pressed
			#touch_idx = event.index
			#if is_pressed:
				#Input.action_press("jump")
			#else:
				#Input.action_release("jump")
		#elif not event.pressed and event.index == touch_idx:
			#is_pressed = false
			#touch_idx = -1


func _on_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			Input.action_press("jump")
		else:
			Input.action_release("jump")# Replace with function body.
