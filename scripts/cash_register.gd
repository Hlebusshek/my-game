extends StaticBody2D
@onready var dialog_ui = DialogUI
@onready var breathe_button: Button = $BreatheButton
@onready var phone_music = get_node("/root/Shop/Phone")
@onready var shop_music = get_node("/root/Shop/ShopMusic")
@onready var thinking_music = get_node("/root/Shop/Thinking")

var choice_pool = {
	80: [
		{ "text": "Согласиться на встречу и подготовить темы\nдля обсуждения", "type": "social_full", "cost": 80},
		{ "text": "Согласиться на встречу,\nно быть рядом с другом", "type": "therapy_support", "cost": 80}
	],
	60: [
		{ "text": "Пойти на встречу, но уйти через час", "type": "social_limited", "cost": 60},
		{ "text": "Согласиться только на официальную часть", "type": "solo_exposure", "cost": 60}
	],
	40: [
		{ "text": "Вежливо отказаться и отключить уведомления", "type": "self_study", "cost": 40},
		{ "text": "Остаться дома, поностальгировать\nрассматривая фото", "type": "grounding_rest", "cost": 40}
	]
}

var has_made_choice = false
var initial_choices = []
var option_40_a = null
var option_40_b = null
var has_revealed_extra = false

func _ready() -> void:
	add_to_group("interactable")

func show_dialog() -> void:
	if not PlayerState.has_tomato_paste:
		dialog_ui.start_dialog([
			"Подойти к кассе... Но пока рано.",
			"Я ещё даже не взял томатную пасту. Нужно сначала найти её на полке."
		])
		await dialog_ui.dialog_finished
		return
	var no_seller_dialog = ["Опять никого нет на кассе...", "Придётся подождать."]
	dialog_ui.start_dialog(no_seller_dialog)
	await dialog_ui.dialog_finished
	await get_tree().create_timer(0.8).timeout
	shop_music.stop()
	phone_music.play()
	thinking_music.play()
	var phone_call = [
		"*Звонит телефон*", "Алло?..",
		"Друг:\nПривет!", "Привет... Что-то случилось?",
		"Друг:\nСлушай, тут через неделю встреча одноклассников! Ты пойдёшь?",
		"Встреча... одноклассников?..",
		"Друг:\nНу да! Все будут! Будет весело, вспомним старое!",
		"Я... не знаю. Давно ни с кем не общался...",
		"Друг:\nДа брось! Все соскучились! Ты же был одним из лучших в классе!",
		"Одним из лучших... Раньше был.",
		"Друг:\nНу так что? Придёшь? Я тебе потом детали скину!",
		"...", "Ладно... Я подумаю."
	]
	dialog_ui.start_dialog(phone_call)
	await dialog_ui.dialog_finished
	await get_tree().create_timer(0.8).timeout
	var reflection = [
		"Встреча одноклассников...",
		"С одной стороны - хочется увидеть всех.",
		"С другой - а вдруг они все изменились? Вдруг я им больше не интересен?",
		"Надо будет подумать..."
	]
	dialog_ui.start_dialog(reflection)
	await dialog_ui.dialog_finished
	_show_choice_menu()

func _generate_choices():
	initial_choices.append(choice_pool[80][randi() % 2].duplicate())
	initial_choices.append(choice_pool[60][randi() % 2].duplicate())
	option_40_a = choice_pool[40][0].duplicate()
	option_40_b = choice_pool[40][1].duplicate()
	initial_choices.append(option_40_a if randi() % 2 == 0 else option_40_b)
	initial_choices.shuffle()

func _show_choice_menu():
	if has_made_choice:
		dialog_ui.start_dialog(["Я уже принял решение. Нужно двигаться дальше."])
		return
	if breathe_button: breathe_button.visible = false
	if initial_choices.is_empty():
		_generate_choices()
	var display_texts = []
	for c in initial_choices:
		display_texts.append(c.text + " (-" + str(c.cost) + " энергии)")
	if has_revealed_extra and option_40_b:
		var is_duplicate = false
		for txt in display_texts:
			if option_40_b.text in txt:
				is_duplicate = true
				break
		if not is_duplicate:
			display_texts.append(option_40_b.text + " (-" + str(option_40_b.cost) + " энергии)")
	if display_texts.size() > 4:
		display_texts.resize(4)
	dialog_ui.start_top_choice_dialog(
		["Как мне лучше распределить свои силы?"],
		display_texts,
		func(choice_idx: int):
			var chosen = null
			if choice_idx < initial_choices.size():
				chosen = initial_choices[choice_idx]
			elif option_40_b and choice_idx == initial_choices.size():
				chosen = option_40_b
			else:
				return
			_handle_choice(chosen)
	)

func _handle_choice(choice: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	if PlayerState.energy < choice.cost:
		dialog_ui.start_dialog(["У меня не хватает внутренних ресурсов для этого..."])
		await dialog_ui.dialog_finished
		has_revealed_extra = true
		_show_choice_menu()
		return
	PlayerState.energy -= choice.cost
	player.energy = PlayerState.energy
	player.update_energy_display()
	PlayerState.choice_score = int(choice.cost / 10)
	PlayerState.last_choice_type = choice.type
	await _call_friend_with_decision(choice.cost)
	has_made_choice = true

func _call_friend_with_decision(cost: int):
	await get_tree().create_timer(1.0).timeout
	var call_dialog = []
	if cost == 80:
		call_dialog = [
			"*Набираю номер друга*",
			"Друг:\nАлло? Привет! Ну что, решил?",
			"Я решил пойти. Да, я приду.",
			"Друг:\nСерьёзно?! Это отлично! Я так рад!",
			"Да... Я тоже. Давно не виделись.",
			"Друг:\nБудет здорово! Все будут в восторге!",
			"Надеюсь... Увидимся."
		]
	elif cost == 60:
		call_dialog = [
			"*Набираю номер друга*",
			"Друг:\nАлло? Привет! Ну что, решил?",
			"Я... попробую прийти. Но если станет тяжело - я уйду.",
			"Друг:\nКонечно! Главное - попробуй. Мы все поймём.",
			"Спасибо... Я постараюсь.",
			"Друг:\nДоговорились! Напишу детали позже.",
			"Хорошо. До связи."
		]
	else:
		call_dialog = [
			"*Набираю номер друга*",
			"Друг:\nАлло? Привет! Ну что, решил?",
			"Я... пока не готов. Мне нужно ещё время.",
			"Друг:\nПонимаю. Это нормально. Не дави на себя.",
			"Спасибо... Просто сейчас мне лучше остаться дома.",
			"Друг:\nКонечно! Когда будешь готов - дай знать. Мы всегда рады.",
			"Спасибо за понимание. Увидимся."
		]
	dialog_ui.start_dialog(call_dialog)
	await dialog_ui.dialog_finished
	var reflection = []
	if cost == 80:
		reflection = ["Я сказал 'да'.", "Это было страшно, но... я чувствую гордость.", "Я сделал шаг вперёд."]
	elif cost == 60:
		reflection = ["Я согласился, но с условиями.", "Это компромисс.", "И это тоже нормально."]
	else:
		reflection = ["Я сказал 'нет'.", "И это не слабость - это забота о себе.", "Иногда нужно время, чтобы восстановиться."]
	dialog_ui.start_dialog(reflection)
	await dialog_ui.dialog_finished
	var shop_scene = get_tree().current_scene
	if shop_scene and shop_scene.has_method("go_to_next_location"):
		await shop_scene.go_to_next_location()
