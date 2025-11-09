extends CharacterBody2D

class_name Enemy


@export var velocidad: float = 60.0
@export var gravedad: float = 900.0

var direccion: int = -1
var vivo: bool = true

@onready var head_area: Area2D = $HeadArea

func _ready():
	head_area.connect("body_entered", Callable(self, "_on_head_area_body_entered"))

func _physics_process(delta):
	if not vivo:
		return

	# aplicar gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.y = 0

	# movimiento horizontal
	velocity.x = velocidad * direccion
	move_and_slide()

	# si choca con algo a los lados, cambiar dirección
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().x != 0:
			direccion *= -1
			break

func _on_head_area_body_entered(body):
	# si el jugador le cae encima, el enemigo muere
	if vivo and body.is_in_group("jugador"):
		_morir()
		# opcional: hacer rebotar al jugador un poco
		if body.has_method("rebote_en_enemigo"):
			body.rebote_en_enemigo()

func _morir():
	vivo = false
	velocity = Vector2.ZERO
	$CollisionShape2D.disabled = true
	head_area.monitoring = false
	# animación de muerte simple (cae)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 10, 0.1)
	tween.tween_property(self, "position:y", position.y + 40, 0.4)
	tween.tween_callback(Callable(self, "queue_free"))
