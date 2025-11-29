extends CharacterBody2D


const WALK_SPEED = 130.0
const ROLL_SPEED = 200
const JUMP_VELOCITY = -300.0
const ROLL_DURATION = 0.35

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum {
	STATE_IDLE,
	STATE_RUN,
	STATE_JUMP,
	STATE_ROLL,
}

var state: int = STATE_IDLE
var roll_timer: float = 0.0
var roll_direction: float = 0.0
var invulnerable: bool = false  # for roll i-frames etc.

var can_jump: bool = false
var coyote_time := 0.12     # you can still jump 120ms after walking off a ledge
var coyote_timer := 0.0

var jump_buffer_time := 0.10
var jump_buffer_timer := 0.0

func _physics_process(delta: float) -> void:
	# ----- Jump buffer -----
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0, jump_buffer_timer - delta)

# ----- Coyote time -----
	if is_on_floor():
		can_jump = true
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0, coyote_timer - delta)
		if coyote_timer <= 0:
			can_jump = false

	if not is_on_floor():
		velocity += get_gravity() * delta

	match state:
		STATE_IDLE:
			_state_idle(delta)
		STATE_RUN:
			_state_run(delta)
		STATE_JUMP:
			_state_jump(delta)
		STATE_ROLL:
			_state_roll(delta)

	move_and_slide()
	
func set_state(new_state: int) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		STATE_IDLE:
			invulnerable = false
			animated_sprite.play("idle")
		STATE_RUN:
			invulnerable = false
			animated_sprite.play("run")
		STATE_JUMP:
			invulnerable = false
			animated_sprite.play("jump")
		STATE_ROLL:
			invulnerable = true           # <-- here: roll = i-frames
			animated_sprite.play("roll")
			roll_timer = ROLL_DURATION
			
func _state_idle(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	# start roll from idle
	if Input.is_action_just_pressed("roll") and is_on_floor():
		_start_roll_from_direction(direction)
		return

	# movement → run
	if direction != 0:
		set_state(STATE_RUN)
		return

	# jump
	if jump_buffer_timer > 0.0 and can_jump:
		jump_buffer_timer = 0.0   # consume buffered jump
		can_jump = false          # no double jump
		velocity.y = JUMP_VELOCITY
		set_state(STATE_JUMP)
		return

	# keep horizontal velocity at 0 in idle
	velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

func _state_run(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	# roll from run
	if Input.is_action_just_pressed("roll") and is_on_floor():
		_start_roll_from_direction(direction)
		return

	# no input → idle
	if direction == 0:
		set_state(STATE_IDLE)
		return

	# jump
	if jump_buffer_timer > 0.0 and can_jump:
		jump_buffer_timer = 0.0   # consume buffered jump
		can_jump = false          # no double jump
		velocity.y = JUMP_VELOCITY
		set_state(STATE_JUMP)
		return

	# move and flip sprite
	velocity.x = direction * WALK_SPEED
	_update_facing(direction)
	animated_sprite.play("run")  # optional, in case you want to re-trigger

func _state_jump(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	# airborne movement
	if direction != 0:
		velocity.x = direction * WALK_SPEED
		_update_facing(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	# landed?
	if is_on_floor():
		if abs(velocity.x) > 0.1:
			set_state(STATE_RUN)
		else:
			set_state(STATE_IDLE)

func _state_roll(delta: float) -> void:
	# constant roll speed in locked direction
	velocity.x = roll_direction * ROLL_SPEED

	roll_timer -= delta
	if roll_timer <= 0.0 or not is_on_floor():
		# end of roll – decide what to go to
		if not is_on_floor():
			set_state(STATE_JUMP)
		elif abs(velocity.x) > 0.1:
			set_state(STATE_RUN)
		else:
			set_state(STATE_IDLE)

func _start_roll_from_direction(direction: float) -> void:
	if direction != 0:
		roll_direction = direction
	else:
		roll_direction = -1.0 if animated_sprite.flip_h else 1.0

	_update_facing(roll_direction)
	set_state(STATE_ROLL)


func _update_facing(direction: float) -> void:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

func is_invulnerable() -> bool:
	return invulnerable

func die() -> void:
	print("You died!")
	Engine.time_scale = 0.5
	get_node("CollisionShape2D").queue_free()
