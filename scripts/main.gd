extends Node

@onready var menu = $Menu
@onready var menu_music = $MenuMusic
@onready var player = $Player
@onready var rain_music = $RainMusic
@onready var dialog_ui = DialogUI
@onready var prompt = InteractionPrompt
@onready var heart_icon = $Player/PlayerUI/HeartIcon
@onready var health_label = $Player/PlayerUI/HealthLabel

func _ready():
	menu_music.play()
	prompt.hide_prompt()
	player.hide()
	health_label.hide()
	heart_icon.hide()
	player.set_process(false)
	$Menu/StartButton.pressed.connect(_on_start_button_pressed)
	$Menu/ExitButton.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	menu_music.stop()
	menu.queue_free()
	player.show()
	rain_music.play()
	player.set_process(true)
	player.start_home_dialog_with_delay()
	
func _on_exit_button_pressed():
	get_tree().quit()

func _process(_delta):
	pass
