extends CharacterBody2D

class_name Player
# --- CONFIGURACIÓN ---
# Coyote time
var coyote_time := 0.12
var coyote_timer := 0.0


# Jump buffer
var jump_buffer_time := 0.25
var jump_buffer_timer := 0.0

# Estado
var is_dead := false
var is_jumping := false

# Físicas
const SPEED := 150.0
const JUMP_VELOCITY := -350.0
const SHORT_HOP_MULTIPLIER := 0.5
const ACCEL := 12000.0
const FRICTION := 10000.0

#Jugador
@export var put_shader: ShaderMaterial
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $"Area2D"

func _ready():
	area.body_entered.connect(_on_area_2d_body_entered)
	

func _physics_process(delta: float) -> void:
	if is_dead:
		sprite.play("Idle")
		velocity += get_gravity() * delta
		move_and_slide()
		return

	# Aplicar gravedad normal
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		is_jumping = false

	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# Saltar
	if (is_on_floor() or coyote_timer > 0.0) and jump_buffer_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		coyote_timer = 0.0 # 🔥 consumir coyote time
		jump_buffer_timer = 0.0

	# Salto corto
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= SHORT_HOP_MULTIPLIER

	# Movimiento lateral
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# --- CORNER CORRECTION ---
	# Si el jugador golpea el techo (solo mientras sube)
	move_and_slide()
	update_animation(direction)

func dead():
	is_dead = true
	sprite.material = put_shader
	await get_tree().create_timer(0.2).timeout 
	$CollisionShape2D.set_deferred("disabled", true)
	get_tree().call_deferred("reload_current_scene")
	

func rebote_en_enemigo(rebote):
	# Si el jugador está cayendo, reiniciamos su impulso hacia arriba
	if velocity.y > 0:
		velocity.y = JUMP_VELOCITY * rebote  # rebote con 60% de la fuerza del salto normal
	else:
		velocity.y = JUMP_VELOCITY * (rebote - 0.1)  # si venía subiendo, rebote un poco más suave


func update_animation(direction: float) -> void:
	if is_dead:
		sprite.play("Idle")
		return
	if is_jumping:
		sprite.play("Jump")
	elif direction != 0:
		sprite.flip_h = (direction < 0)
		sprite.play("Run")
	else:
		sprite.play("Idle")


func _on_pitfall_body_entered(body: Node2D) -> void:
	if body.has_method("dead"):
		body.dead()
	else:
		body.queue_free()
		


func _on_area_2d_body_entered(_body: Node2D):
	$".".dead()
