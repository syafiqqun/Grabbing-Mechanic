extends MeshInstance


func _process(delta: float) -> void:
	
	var direction = Vector3()
	
	if Input.is_action_pressed("move_right"):
		global_translation.x += 10 * delta
