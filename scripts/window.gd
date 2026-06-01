extends Sprite2D

@onready var player = $Player
@onready var dialog_ui = DialogUI

func _ready():
	add_to_group("interactable")
	

func show_dialog():
	var dialog = ["Опять дождь... Как будто весь мир плачет.",
	"Интересно, если я простою здесь достаточно долго – может, смоет и меня?"]
	dialog_ui.start_dialog(dialog)

func _process(_delta: float) -> void:
	pass

func _on_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass
