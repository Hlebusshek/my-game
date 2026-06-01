extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/Label

func show_prompt(text: String = "Нажми F"):
	label.text = text
	panel.visible = true

func hide_prompt():
	panel.visible = false
