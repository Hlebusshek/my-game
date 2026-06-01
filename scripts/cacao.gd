extends Sprite2D
@onready var dialog_ui = DialogUI

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	var energy_gain = 25
	if PlayerState.has_drunk_cocoa:
		energy_gain = 10
	else:
		PlayerState.has_drunk_cocoa = true
	var dialog = [
		"Кружка с какао всё ещё тёплая.",
		"Горячий напиток не решит всех проблем, но поможет пережить этот момент."
	]
	dialog_ui.start_dialog(dialog)
	await dialog_ui.dialog_finished
	PlayerState.energy = min(PlayerState.energy + energy_gain, PlayerState.MAX_ENERGY)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.energy = PlayerState.energy
		player.update_energy_display()
	remove_from_group("interactable")
	modulate.a = 0.5
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

func get_interaction_text() -> String:
	return "Пить какао F"
