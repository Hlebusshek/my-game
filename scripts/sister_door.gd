extends Sprite2D
@onready var dialog_ui = DialogUI
@onready var door_music = get_node("/root/second_room/DoorMusic")
@onready var thinking_music = get_node("/root/second_room/Thinking")
var has_interacted = false
var initial_choices = []
var extra_choices = []
var has_revealed_extra = false
var sister_node = null

var choice_pool = {
	80: [
		{ "text": "Стать главным координатором: найти\nгрузчиков, составить план разгрузки", "type": "full_help", "cost": 80 },
		{ "text": "Согласиться и заранее купить всем еду,\nчтобы снять напряжение", "type": "organize", "cost": 80 }
	],
	60: [
		{ "text": "Согласиться, но только до обеда", "type": "limited_time", "cost": 60 },
		{ "text": "Взять на себя только упаковку вещей", "type": "partial_help", "cost": 60 }
	],
	40: [
		{ "text": "Не ехать, но провести вечер в\nсозвоне с сестрой", "type": "polite_refusal", "cost": 40 },
		{ "text": "Предложить помощь в другой день", "type": "alternative", "cost": 40 }
	]
}

func _ready() -> void:
	add_to_group("interactable")
	var btn = _get_breathe_button()
	if btn:
		btn.visible = false

func _get_breathe_button() -> Button:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("BreatheButton"):
		return current_scene.get_node("BreatheButton")
	return null

func show_dialog() -> void:
	door_music.play()
	thinking_music.play()
	if has_interacted: return
	var current_scene = get_tree().current_scene
	if current_scene.has_method("reveal_sister"):
		current_scene.reveal_sister()
	var sister_intro = [
		"Дверь открывается. В комнату заходит сестра.",
		"Сестра: Привет! Извини, что без предупреждения.",
		"Сестра: У меня в выходные переезд. Поможешь?",
		"Сестра: Я знаю, ты сейчас занят, но мне правда нужна поддержка..."
	]
	dialog_ui.start_dialog(sister_intro)
	await dialog_ui.dialog_finished
	_generate_choices()
	_show_choice_menu()

func _generate_choices():
	initial_choices.clear()
	extra_choices.clear()
	has_revealed_extra = false
	var score = PlayerState.choice_score
	if score > 4:
		initial_choices.append(choice_pool[40][randi() % 2].duplicate())
		initial_choices.append(choice_pool[60][randi() % 2].duplicate())
		initial_choices.append(choice_pool[80][randi() % 2].duplicate())
		var used_40_text = initial_choices[0].text
		extra_choices.append(choice_pool[40][0].duplicate() if choice_pool[40][0].text != used_40_text else choice_pool[40][1].duplicate())
	else:
		var config_is_two_40s = randi() % 2 == 0
		if config_is_two_40s:
			initial_choices.append(choice_pool[40][0].duplicate())
			initial_choices.append(choice_pool[40][1].duplicate())
			initial_choices.append(choice_pool[60][randi() % 2].duplicate())
			var used_60_text = initial_choices[2].text
			extra_choices.append(choice_pool[60][0].duplicate() if choice_pool[60][0].text != used_60_text else choice_pool[60][1].duplicate())
		else:
			initial_choices.append(choice_pool[40][randi() % 2].duplicate())
			initial_choices.append(choice_pool[60][0].duplicate())
			initial_choices.append(choice_pool[60][1].duplicate())
			var used_40_text = initial_choices[0].text
			extra_choices.append(choice_pool[40][0].duplicate() if choice_pool[40][0].text != used_40_text else choice_pool[40][1].duplicate())
	initial_choices.shuffle()

func _show_choice_menu():
	if has_interacted:
		dialog_ui.start_dialog(["Я уже принял решение. Нужно двигаться дальше."])
		return
	if initial_choices.is_empty():
		_generate_choices()
	var display_texts = []
	for c in initial_choices:
		display_texts.append(c.text + " (-" + str(c.cost) + " энергии)")
	if has_revealed_extra:
		for c in extra_choices:
			var is_duplicate = false
			for txt in display_texts:
				if c.text in txt:
					is_duplicate = true
					break
			if not is_duplicate:
				display_texts.append(c.text + " (-" + str(c.cost) + " энергии)")
	if display_texts.size() > 4:
		display_texts.resize(4)
	dialog_ui.start_top_choice_dialog(
		["Как я отвечу сестре?"],
		display_texts,
		func(choice_idx: int):
			var chosen = null
			if choice_idx < initial_choices.size():
				chosen = initial_choices[choice_idx]
			else:
				var extra_idx = choice_idx - initial_choices.size()
				if extra_idx < extra_choices.size():
					chosen = extra_choices[extra_idx]
			if chosen:
				_handle_choice(chosen)
	)

func _handle_choice(choice: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	if PlayerState.energy < choice.cost:
		dialog_ui.start_dialog(["У меня не хватает внутренних ресурсов для этого..."])
		await dialog_ui.dialog_finished
		has_revealed_extra = true
		if PlayerState.energy < 40:
			var butn = _get_breathe_button()
			if butn:
				butn.visible = true
				await butn.pressed
				butn.visible = false
				await _run_breathing_minigame()
				_show_choice_menu()
				return
		_show_choice_menu()
		return
	PlayerState.energy -= choice.cost
	if player:
		player.energy = PlayerState.energy
		player.update_energy_display()
	PlayerState.choice_score += int(choice.cost / 10)
	PlayerState.last_choice_type = choice.type
	var response = _get_sister_response(choice.type)
	dialog_ui.start_dialog([response])
	await dialog_ui.dialog_finished
	has_interacted = true
	remove_from_group("interactable")
	var btn = _get_breathe_button()
	if btn: btn.visible = false
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("go_to_next_location"):
		await current_scene.go_to_next_location()

func _get_sister_response(type: String) -> String:
	match type:
		"full_help", "organize":
			return "Сестра: Спасибо! Ты настоящий спаситель. Я так рада, что могу на тебя положиться!"
		"limited_time", "partial_help":
			return "Сестра: Понимаю. Любая помощь важна. Спасибо, что нашёл время!"
		"polite_refusal", "alternative":
			return "Сестра: Ничего страшного. Береги себя. Если передумаешь — звони!"
		_:
			return "Сестра: Хорошо, я тебя поняла."

func _run_breathing_minigame() -> void:
	var minigame_scene = preload("res://scenes/breathing_minigame.tscn")
	var minigame = minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	await minigame.minigame_finished
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.energy = PlayerState.energy
		player.update_energy_display()

func get_interaction_text() -> String:
	return "Открыть F"
