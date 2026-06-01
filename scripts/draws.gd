extends Sprite2D

@onready var dialog_ui = DialogUI

var has_interacted = false

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	if has_interacted: return
	has_interacted = true
	var dialog = [
		"Мои эскизы...",
		"Надо глянуть, как рисуют другие. Для мотивации и идей."
	]
	dialog_ui.start_dialog(dialog)
	await dialog_ui.dialog_finished
	var room = get_tree().current_scene
	if room.has_method("trigger_phone_sequence"):
		room.trigger_phone_sequence()

func get_interaction_text() -> String:
	return "Рисунки F"
