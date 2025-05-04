extends Node

@onready var menu = $Menu
@onready var player = $Player
@onready var dialog_ui = DialogUI
@onready var prompt = InteractionPrompt

func _ready():
	prompt.hide_prompt()
	player.hide()
	player.set_process(false)
	$Menu/StartButton.pressed.connect(_on_start_button_pressed)


func _on_start_button_pressed():
	menu.queue_free()
	player.show()
	player.set_process(true)

func _process(delta):
	pass
