extends Sprite2D

@onready var player = get_node("/root/Main/Player")
@export var next_scene_path: String = "res://Street.tscn"

func _ready():
	add_to_group("interactable")
	
@onready var dialog_ui = DialogUI

#
#
func show_dialog():
	dialog_ui.start_dialog_with_choices(
		["Вы действительно хотите выйти на улицу?"],
		["Да", "Нет"],
		func(choice_idx):               
			if choice_idx == 0:
				player.street = true
				get_tree().change_scene_to_file("res://street.tscn")
			else:
				pass
	)
	dialog_ui.choice_button


func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass
