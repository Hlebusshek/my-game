extends Sprite2D
@onready var dialog_ui = DialogUI

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	var dialog = [
		"Кровать всё ещё неубрана, но я больше не чувствую вину за это.",
		"Иногда отдых важнее идеального порядка."
	]
	dialog_ui.start_dialog(dialog)
