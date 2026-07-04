extends Enemy

func special_animation():
	sprite.flip_h = true
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x + 1000, 2.0)
	tween.tween_callback(Callable(self, "queue_free"))
	
