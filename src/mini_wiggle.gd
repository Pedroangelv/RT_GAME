extends Enemy

func _on_interaction_body_entered(body: Node2D) -> void:
	if not vivo:
		return
	if body.is_in_group("jugador"):
		body.dead()
