extends Node2D

const SPEED = 60

var direction = 1
var is_dead = false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead:
		return  # stop movement when dead
		
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	
	position.x +=  direction * delta * SPEED

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.state == body.STATE_ROLL:
		die()
			
func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	animated_sprite.play("death")
	
	print("awaiting death")
	await animated_sprite.animation_finished
	print("finished")
	queue_free()
