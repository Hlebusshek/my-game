extends Sprite2D
@onready var dialog_ui = DialogUI

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	var dialog = [
		"Свет в окне кажется чуть ярче, чем раньше..."
	]
	dialog_ui.start_dialog(dialog)
