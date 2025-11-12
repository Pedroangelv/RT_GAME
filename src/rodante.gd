extends RigidBody2D

@export var impulso: float = 500
var direccion: Vector2 = Vector2.RIGHT

func _ready():
	apply_impulse(Vector2.ZERO, direccion * impulso)

func _integrate_forces(state):
	# Si choca con algo, cambia de dirección
	if linear_velocity.length() < 10:
		direccion.x *= -1
		linear_velocity = direccion * impulso
