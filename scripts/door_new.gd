extends Sprite2D
@onready var dialog_ui = DialogUI
var next_scene_path: String = GameResources.scenes["shop"]
@onready var door_music = get_node("/root/new_room/DoorMusic")

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	door_music.play()
	dialog_ui.start_dialog_with_choices(
		["Выйти в магазин за продуктами?"],
		["Да, пора", "Я не закончил"],
		func(choice_idx: int):
			if choice_idx == 0:
				# Помечаем, что игрок вышел (если нужно для логики следующих сцен)
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.street = true
				get_tree().change_scene_to_file(next_scene_path)
			else:
				pass
	)

func get_interaction_text() -> String:
	return "Выйти F"
