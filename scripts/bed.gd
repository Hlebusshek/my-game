extends Sprite2D

@onready var player = $Player
var dialog_ui = DialogUI

func _ready():
	add_to_group("interactable")

func show_dialog():
	var dialog = ["Кровать выглядит неубранной...","Но у меня нет сил даже на это."]
	dialog_ui.start_dialog(dialog)

func _process(_delta: float) -> void:
	pass
