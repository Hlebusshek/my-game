extends StaticBody2D
@onready var dialog_ui = DialogUI

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	var dialog = [
		"Нашел. Теперь нужно идти на кассу.",
	]
	dialog_ui.start_dialog(dialog)
	await dialog_ui.dialog_finished 
	remove_from_group("interactable")
	PlayerState.has_tomato_paste = true

func get_interaction_text() -> String:
	return "Том. паста F"
