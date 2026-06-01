extends Sprite2D

@onready var dialog_ui = DialogUI

func _ready():
	add_to_group("interactable")
#
func show_dialog():
	var dialog = ["Эскизы... Все начатые, ни одного законченного.",
	"Почему все, что я создаю, выглядит таким... пустым?"]
	dialog_ui.start_dialog(dialog)

func _process(_delta: float) -> void:
	pass

func _on_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass
