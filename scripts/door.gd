extends Sprite2D

@onready var player = get_node("/root/Main/Player")
@export var next_scene_path: String = GameResources.scenes["street"]
@onready var rain_music = get_node("/root/Main/RainMusic")
@onready var door_music = get_node("/root/Main/DoorMusic")
@onready var dialog_ui = DialogUI

func _ready():
	add_to_group("interactable")

func show_dialog():
	door_music.play()
	dialog_ui.start_dialog_with_choices(
		["Вы действительно хотите выйти на улицу?"],
		["Да", "Нет"],
		func(choice_idx):               
			if choice_idx == 0:
				player.street = true
				get_tree().change_scene_to_file(GameResources.scenes["street"])
				rain_music.stop()
			else:
				pass
	)

func _process(_delta: float) -> void:
	pass

func _on_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass
