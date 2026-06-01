extends Node

@onready var dialog_ui = DialogUI
@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var room1_music = $RoomMusic
@onready var room2_music = $RoomMusic2
@onready var room3_music = $RoomMusic3
@onready var end_music = $EndMusic
@onready var thinking_music = $Thinking
@onready var bg_room_low = $RoomLow
@onready var bg_room = $Room
@onready var bg_room_cool = $RoomCool
@onready var phone_overlay = $Phone
@onready var breathe_button: Button = $BreatheButton
@onready var black_bg = get_node_or_null("CanvasLayer/BlackBackground")
@onready var skip_label = get_node_or_null("CanvasLayer/Label")
var has_interacted = false
var phone_sequence_triggered = false
var initial_choices = []
var extra_choices = []
var has_revealed_extra = false
var player_node = null
var choice_pool = {
	80: [
		{ "text": "Сесть и рисовать, пока не закончу работу", "type": "full_immersion", "cost": 80 },
		{ "text": "Попробовать повторить технику увиденного мастера", "type": "full_immersion_b", "cost": 80 }
	],
	60: [
		{ "text": "Порисовать минут 20, просто чтобы размять руку", "type": "short_session", "cost": 60 },
		{ "text": "Сделать пару быстрых набросков в блокноте", "type": "sketching", "cost": 60 }
	],
	40: [
		{ "text": "Отложить всё на завтра, сейчас не в настроении", "type": "delay", "cost": 40 },
		{ "text": "Просто пересмотреть краски и убрать их в шкаф", "type": "avoidance", "cost": 40 }
	]
}

func _ready() -> void:
	prompt.hide_prompt()
	player_node = player_scene.instantiate()
	add_child(player_node)
	await get_tree().process_frame
	var heart_icon = player_node.get_node_or_null("PlayerUI/HeartIcon")
	var health_label = player_node.get_node_or_null("PlayerUI/HealthLabel")
	if heart_icon: heart_icon.hide()
	if health_label: health_label.hide()
	player_node.show()
	player_node.position = Vector2(250, 300)
	player_node.scale = Vector2(2, 2)
	player_node.speed = 200
	_update_background()
	if breathe_button: breathe_button.visible = false
	_start_story_sequence()

func _start_story_sequence() -> void:
	if has_interacted: return
	await get_tree().create_timer(0.5).timeout
	DialogUI.start_dialog([
		"Психолог рекомендовал вернуться к старому хобби — рисованию.",
		"Говорит, что это может помочь снизить тревогу и вернуть вкус к жизни...",
		"Я решил попробовать..."
	])
	await DialogUI.dialog_finished

func trigger_phone_sequence() -> void:
	if phone_sequence_triggered or has_interacted: return
	phone_sequence_triggered = true
	if prompt: prompt.hide_prompt()
	DialogUI.start_dialog(["Разглядываю старые работы... Получается не так уж плохо."])
	await DialogUI.dialog_finished
	if phone_overlay: phone_overlay.visible = true
	if player_node: player_node.hide()
	if bg_room_low: bg_room_low.visible = false
	if bg_room: bg_room.visible = false
	if bg_room_cool: bg_room_cool.visible = false
	await get_tree().create_timer(0.5).timeout
	DialogUI.start_dialog([
		"Листаю ленту... Вижу работу одного популярного художника.",
		"До чего же красиво... Линии, свет, атмосфера.",
		"А вдруг у меня никогда так не получится?",
		"Старые сомнения возвращаются..."
	])
	await DialogUI.dialog_finished
	if phone_overlay: phone_overlay.visible = false
	if player_node: player_node.show()
	_update_background() 
	room1_music.stop()
	room2_music.stop()
	room3_music.stop()
	thinking_music.play()
	await get_tree().create_timer(0.5).timeout
	_generate_choices()
	_show_choice_menu()

func _update_background() -> void:
	var score = PlayerState.choice_score
	if bg_room_low: bg_room_low.visible = score <= 8
	if bg_room: bg_room.visible = score > 8 and score <= 10
	if bg_room_cool: bg_room_cool.visible = score > 10
	if score <= 8:
		room1_music.play()
	elif score <=10:
		room2_music.play()
	else:
		room3_music.play()

func _get_breathe_button() -> Button:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("BreatheButton"):
		return current_scene.get_node("BreatheButton")
	return null

func _generate_choices() -> void:
	initial_choices.clear()
	extra_choices.clear()
	has_revealed_extra = false
	var score = PlayerState.choice_score
	if score > 10:
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

func _show_choice_menu() -> void:
	if has_interacted:
		DialogUI.start_dialog(["Я уже принял решение. Нужно двигаться дальше."])
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
	DialogUI.start_top_choice_dialog(
		["Как я поступлю со своими сомнениями?"],
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

func _handle_choice(choice: Dictionary) -> void:
	if PlayerState.energy < choice.cost:
		DialogUI.start_dialog(["У меня не хватает внутренних ресурсов для этого..."])
		await DialogUI.dialog_finished
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
	PlayerState.choice_score += int(choice.cost / 10)
	PlayerState.last_choice_type = choice.type
	_update_player_energy()
	var response = _get_response(choice.type)
	DialogUI.start_dialog([response])
	await DialogUI.dialog_finished
	has_interacted = true
	if breathe_button: breathe_button.visible = false
	DialogUI.start_dialog(["День подходит к концу. Завтра будет новый шаг."])
	await DialogUI.dialog_finished
	thinking_music.stop()
	_end_game_sequence()

func _update_player_energy() -> void:
	if player_node:
		player_node.energy = PlayerState.energy
		player_node.update_energy_display()

func _run_breathing_minigame() -> void:
	var minigame_scene = preload("res://scenes/breathing_minigame.tscn")
	var minigame = minigame_scene.instantiate()
	get_tree().root.add_child(minigame)
	await minigame.minigame_finished
	_update_player_energy()

func _get_response(type: String) -> String:
	match type:
		"full_immersion", "full_immersion_b":
			return "Я сел за стол и забыл про время. Краски легли так, как давно не ложились. Сомнения отступили перед процессом."
		"short_session", "sketching":
			return "Немного порисовал. Не идеально, но рука вспомнила движения. Это уже победа."
		"delay", "avoidance":
			return "Решил не давить на себя сегодня. Иногда отдых — это тоже часть пути. Завтра попробую снова."
		_:
			return "Я сделаю так, как чувствую."

func _show_sequential_text(lines: Array, display_duration: float = 2.0, fade_duration: float = 0.8) -> void:
	if not black_bg or not skip_label:
		return
	black_bg.visible = true
	skip_label.visible = true
	black_bg.modulate.a = 0.0
	skip_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(black_bg, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	for line in lines:
		skip_label.text = line
		var fade_in = create_tween()
		fade_in.tween_property(skip_label, "modulate:a", 1.0, fade_duration).set_ease(Tween.EASE_IN_OUT)
		await fade_in.finished
		await get_tree().create_timer(display_duration).timeout
		var fade_out = create_tween()
		fade_out.tween_property(skip_label, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN_OUT)
		await fade_out.finished

func _end_game_sequence() -> void:
	end_music.play()
	if not black_bg or not skip_label:
		push_error("⚠️ Отсутствуют CanvasLayer/BlackBackground или Label для концовки!")
		get_tree().change_scene_to_file(GameResources.scenes["main"])
		return
	var score = PlayerState.choice_score
	var final_lines: Array[String]
	if score < 15: 
		final_lines = [
			"Прошел год...",
			"Путь к себе оказался длиннее, чем я думал.",
			"Мне нужно ещё много времени и\nподдержки, чтобы стать лучше.",
			"Но я не сдаюсь."
		]
	elif score < 17: 
		final_lines = [
			"Прошел год...",
			"Я вижу заметные улучшения.",
			"Терапия работает, но я пока\nне готов её бросать.",
			"Впереди ещё работа над собой."
		]
	else: 
		final_lines = [
			"Прошел год...",
			"Я чувствую себя лучше.\nНе идеально, но достаточно.",
			"Я готов двигаться дальше уже\nбез постоянной опоры на терапию.",
			"Впереди новая глава."
		]
	await _show_sequential_text(final_lines, 2.5, 0.8)
	await get_tree().create_timer(1.0).timeout
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("reset_game_state"):
		player.reset_game_state()
	else:
		PlayerState.reset_all()
	black_bg.modulate.a = 1.0
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(GameResources.scenes["main"])
