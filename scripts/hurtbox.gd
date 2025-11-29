extends Area2D

@onready var timer: Timer = $Timer

@export var lethal: bool = false

func _on_body_entered(body: Node2D) -> void:
	# Only care about player
	if not body.is_in_group("player"):
		return

	# If player can be invulnerable and currently is, maybe ignore
	if body.has_method("is_invulnerable"):
		if body.is_invulnerable() and not lethal:
			return

	if body.has_method("die"):
		body.die()

	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
