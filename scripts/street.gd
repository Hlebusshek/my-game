extends Node
@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var rain_music = $RainMusic

func _ready() -> void:
	prompt.hide_prompt()
	var player = player_scene.instantiate()
	rain_music.play()
	add_child(player)
	var energy_icon = player.get_node_or_null("PlayerUI/EnergyIcon")
	var energy_label = player.get_node_or_null("PlayerUI/EnergyLabel")
	if energy_icon: energy_icon.hide()
	if energy_label: energy_label.hide()
	if player.park:
		player.position = Vector2(20, 270)
	else:
		player.position = Vector2(20, 230)
	player.speed = 50

func _process(_delta: float) -> void:
	pass
