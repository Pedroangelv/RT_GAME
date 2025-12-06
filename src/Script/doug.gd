extends CharacterBody2D

class_name Player
# --- CONFIGURACIÓN ---
# Coyote time
var coyote_time := 0.12
var coyote_timer := 0.0
var has_jumped := false

# Jump buffer
var jump_buffer_time := 0.25
var jump_buffer_timer := 0.0

# Estado
var is_dead := false
var is_jumping := false

# Físicas
const SPEED := 200.0
const JUMP_VELOCITY := -350.0
const SHORT_HOP_MULTIPLIER := 0.5

#Jugador
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_dead:
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
		has_jumped = false
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	# Saltar
	if (is_on_floor() or coyote_timer > 0) and jump_buffer_timer > 0 and not has_jumped:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		has_jumped = true
		jump_buffer_timer = 0.0

	# Salto corto
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= SHORT_HOP_MULTIPLIER

	# Movimiento lateral
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# --- CORNER CORRECTION ---
	# Si el jugador golpea el techo (solo mientras sube)
	move_and_slide()
	update_animation(direction)

func dead():
	is_dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()
	get_tree().call_deferred("reload_current_scene")
	

func rebote_en_enemigo():
	# Si el jugador está cayendo, reiniciamos su impulso hacia arriba
	if velocity.y > 0:
		velocity.y = JUMP_VELOCITY * 0.6  # rebote con 60% de la fuerza del salto normal
	else:
		velocity.y = JUMP_VELOCITY * 0.5  # si venía subiendo, rebote un poco más suave


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
		
