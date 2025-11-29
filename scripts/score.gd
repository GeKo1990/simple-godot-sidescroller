extends Label

@onready var score_label: Label = $"."
@onready var game_manager: Node = %GameManager

func _on_ready() -> void:
	score_label.text = str(game_manager.score)
	
	game_manager.score_changed.connect(_on_score_changed)
	
func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
