extends Sprite2D
@onready var dialog_ui = DialogUI

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	var dialog = [
		"На столе всё ещё лежат старые эскизы.",
		"Наверное не так страшно, что я их не закончил?.."
	]
	dialog_ui.start_dialog(dialog)
