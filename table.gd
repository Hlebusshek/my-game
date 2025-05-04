extends Sprite2D

@onready var player = $Player

func _ready():
	add_to_group("interactable")
	
@onready var dialog_ui = DialogUI

#
#
func show_dialog():
	var dialog = ["Эскизы... Все начатые, ни одного законченного.",
	"Почему все, что я создаю, выглядит таким... пустым?"]
	dialog_ui.start_dialog(dialog)

func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass
