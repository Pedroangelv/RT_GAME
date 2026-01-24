extends CharacterBody2D

class_name Player
# --- CONFIGURACIÓN ---
# Coyote time
var coyote_time := 0.2
var coyote_timer := 0.0


# Jump buffer
var jump_buffer_time := 0.25
var jump_buffer_timer := 0.0

# Estado
var is_dead := false
var is_jumping := false

# Físicas
const SPEED := 150.0
const JUMP_VELOCITY := -355.0
const SHORT_HOP_MULTIPLIER := 0.5
const ACCEL := 12000.0
const FRICTION := 10000.0

var jump_hold_time := 0.0
const MAX_JUMP_HOLD := 0.15
var jump_was_cut := false

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
	if Input.is_action_pressed("jump"):
		jump_hold_time += delta
	else:
		jump_hold_time = 0.0
	# Aplicar gravedad normal
	if is_on_floor():
		is_jumping = false
		jump_was_cut = false
	else:
		velocity += get_gravity() * delta

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
	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_jumping:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_was_cut = false
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
	# Salto corto
	if is_jumping and velocity.y < 0 and not jump_was_cut:
		if not Input.is_action_pressed("jump"):
			velocity.y *= SHORT_HOP_MULTIPLIER
			jump_was_cut = true
			
	# Movimiento lateral
	var accel := ACCEL
	var friction := FRICTION

	if not is_on_floor():
		accel *= 0.5
		friction *= 0.5
	

	var direction := 0.0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1


	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
	else:
		if is_on_floor():
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

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
		velocity.y = JUMP_VELOCITY * rebote # si venía subiendo, rebote un poco más suave


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
		


func _on_area_2d_body_entered(_body):
	$".".dead()
	
