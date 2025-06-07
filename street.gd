extends Node
@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var rain_music = $RainMusic

func _ready() -> void:
	prompt.hide_prompt()
	var player = player_scene.instantiate()
	rain_music.play()
	add_child(player)
	if player.park:
		player.position = Vector2(20, 270)
	else:
		player.position = Vector2(20, 230)
	player.speed = 50

func _process(delta: float) -> void:
	pass
