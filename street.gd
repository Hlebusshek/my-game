extends Node
@onready var player_scene = preload("res://player.tscn")
@onready var prompt = InteractionPrompt

func _ready() -> void:
	prompt.hide_prompt()
	var player = player_scene.instantiate()
	add_child(player)
	player.position = Vector2(20, 230)
	player.speed = 50

func _process(delta: float) -> void:
	pass
