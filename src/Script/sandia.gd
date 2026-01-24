extends CharacterBody2D

class_name Enemy 

@export var rebote: float = 0.6
@export var boss: bool = false
@export var attemps_kill: int = 1
@export var velocidad: float = 60.0
@export var gravedad: float = 900.0
@onready var sprite: Sprite2D = $Sprite2D
@export var rotable: bool = true
@export var flipable: bool = false

var direccion: int = -1
var vivo: bool = true

@onready var head_area = $HeadArea

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
	
	#rotacion
	if rotable:
		sprite.rotation += delta * 3 * direccion
	# movimiento horizontal
	velocity.x = velocidad * direccion
	move_and_slide()

	# si choca con algo a los lados, cambiar dirección
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().x != 0:
			if flipable:
				sprite.flip_h = (direccion < 0)
			direccion *= -1
			break

func _on_head_area_body_entered(body):
	# si el jugador le cae encima, el enemigo muere
	if !boss:
		if vivo and body.is_in_group("jugador"):
			_morir()
			#hacer rebotar al jugador un poco
			
			body.rebote_en_enemigo(rebote)
	else:
		if attemps_kill == 1 and vivo and body.is_in_group("jugador"):
			_morir()
			body.rebote_en_enemigo(rebote)
		else:
			if body.is_in_group("jugador"):
				attemps_kill -= 1
				body.rebote_en_enemigo(rebote)
			

func _morir():
	$interaction/CollisionPolygon2D.set_deferred("disabled", true)
	vivo = false
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	head_area.set_deferred("monitoring", false)
	
	
	# animación de muerte simple (cae)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 10, 0.1)
	tween.tween_property(self, "position:y", position.y + 40, 0.4)
	tween.tween_callback(Callable(self, "queue_free"))


func _on_interaction_body_entered(body: Node2D) -> void:
	if not vivo:
		return
	if body.is_in_group("jugador"):
		body.dead()
	
