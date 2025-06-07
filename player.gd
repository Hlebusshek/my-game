extends CharacterBody2D

@export var speed = 200
var screen_size
var player_size = Vector2(32, 32)
var near_bed = false
@onready var dialog_ui = DialogUI
@onready var prompt = InteractionPrompt
@onready var count_rip = rip_count
@onready var anxiety = GameResources.load_scene("anxiety_boss").instantiate()
@onready var fade_rect = $PlayerUI/ColorRect
@onready var damage_sound = $DamageSound
@onready var phone_music = $Phone
@onready var depress_music = get_node("/root/DepressionBoss/Fight")
@onready var anxiety_music = get_node("/root/AnxietyBoss/Fight")
@onready var rain_music = get_node("/root/Street/RainMusic")
@onready var boss_roar = $BossRoar
var current_interactable: Node = null
const INTERACTION_DISTANCE = 40
var in_boss_fight: bool = false
var health: int = 3
var street: bool = false
var park: bool = false
var anxiety_rip: bool = false
var flag: bool = false
var home: bool = false
var home_dialog: bool = false
@onready var heart_icon = $PlayerUI/HeartIcon
@onready var health_label = $PlayerUI/HealthLabel

func _ready():
	$Area2D.connect("area_entered", _on_area_entered)
	add_to_group("player")
	if get_tree().current_scene.scene_file_path == GameResources.scenes["main"]:
		home = true
	if get_tree().current_scene.scene_file_path == GameResources.scenes["street"]:
		street = true
		home = false
	if get_tree().current_scene.scene_file_path == GameResources.scenes["park"]:
		park = true
		street = false
	screen_size = get_viewport_rect().size
	self.collision_mask = 1
	position.x = 250
	position.y = 300
	update_health_display()

func fade_and_change_scene(scene_path: String) -> void:
	fade_rect.modulate.a = 0
	fade_rect.visible = true
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file(scene_path)

func update_health_display():
	health_label.text = str(health)
	
func _on_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		take_damage(1)
		area.queue_free()
		
func take_damage(amount: int):
	damage_sound.play()
	health -= amount
	if health >=0:
		update_health_display()
	if health == 0:
		game_over()

func game_over():
	var boss = get_boss()
	
	if park:
		handle_depression_ending(boss)
		return
	
	handle_standard_ending(boss)

func get_boss():
	return get_tree().get_first_node_in_group("depression_boss" if park else "anxiety_boss")

func handle_depression_ending(boss):
	count_rip.depression_rip_count += 1
	boss.can_attack = false
	boss.fight_music.stop()
	
	if count_rip.depression_rip_count == 3:
		await show_hospital_dialogs()
		await fade_and_change_scene(GameResources.scenes["hospital"])
		return
	
	await show_retry_dialog()
	reload_scene(boss)

func handle_standard_ending(boss):
	boss.can_attack = false
	await show_retry_dialog()
	reload_scene(boss)

func show_hospital_dialogs():
	var dialogs = [
		["Я так больше не могу... Мне правда нужна помощь..."],
		["*звонок телефона*", "А-алло?..", 
		 "Голос из телефона:\nЗдравствуйте, это клиника 'Душевный баланс'.",
		 "Голос из телефона:\nВы записаны на 15:00, ждём вас сегодня?", "...",
		 "/Точно... Они смогут мне помочь.../", "/Я справлюсь!!/", 
		 "Да! Я обязательно приду! Скоро буду!"]
	]
	
	for dialog in dialogs:
		DialogUI.start_dialog(dialog)
		await DialogUI.dialog_finished
		if dialog == dialogs[0]:
			phone_music.play()

func show_retry_dialog():
	DialogUI.start_dialog(["Я чувствую себя нехорошо...", "Надо попробовать еще раз!"])
	await DialogUI.dialog_finished

func reload_scene(boss):
	if get_tree():
		get_tree().reload_current_scene()
	boss.can_attack = true

func _process(delta):
	if not is_instance_valid(dialog_ui) or dialog_ui.is_dialog_active:
		return
	
	handle_interaction()
	handle_movement(delta)

func handle_interaction():
	var closest = find_closest_interactable()
	
	if current_interactable != closest:
		prompt.hide_prompt() if current_interactable else null
		current_interactable = closest
		update_prompt()
	
	if Input.is_action_just_pressed("interact") and is_valid_interactable():
		current_interactable.show_dialog()

func find_closest_interactable():
	var closest = null
	var min_dist = INTERACTION_DISTANCE
	
	for interactable in get_tree().get_nodes_in_group("interactable"):
		var dist = global_position.distance_to(interactable.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = interactable
	return closest

func update_prompt():
	if current_interactable:
		if current_interactable.has_method("get_interaction_text"):
			var custom_text = current_interactable.get_interaction_text()
			if custom_text != "":
				prompt.show_prompt(custom_text)
			else:
				prompt.show_prompt()
		else:
			prompt.show_prompt()

func is_valid_interactable():
	return current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("show_dialog")

func handle_movement(delta):
	var velocity = get_input_velocity()
	update_position(velocity, delta)
	update_animation(velocity)

func get_input_velocity():
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return input.normalized() * speed if input.length() > 0 else Vector2.ZERO

func update_position(velocity, delta):
	position += velocity * delta
	position = position.clamp(
		Vector2(player_size.x/2, player_size.y/2), 
		Vector2(screen_size.x - player_size.x/2, screen_size.y - player_size.y/2))
	move_and_slide()

func update_animation(velocity):
	if velocity.length_squared() > 0:
		if abs(velocity.x) > abs(velocity.y):
			$AnimatedSprite2D.play("walk_right" if velocity.x > 0 else "walk_left")
		else:
			$AnimatedSprite2D.play("walk_forward" if velocity.y > 0 else "walk_back")
	else:
		$AnimatedSprite2D.play("walk_back" if $AnimatedSprite2D.animation == "walk_back" else "walk_forward")

func start_home_dialog_with_delay():
	if home and not home_dialog:
		home_dialog = true
		await get_tree().create_timer(1.0).timeout
		var dialog = [
			"Я не выходил из дома уже... даже не помню сколько недель...",
			"Каждый день - как тяжёлая ноша. Даже простые дела требуют невероятных усилий...",
			"Но... после месяцев мучений я всё же записался к психотерапевту.","Сегодня день приёма.",
			"Может быть... просто может быть, мне хоть немного станет легче?",
			"У меня есть еще немного времени до выхода."
		]
		DialogUI.start_dialog(dialog)
		
func _physics_process(delta):
	if position.x > 200 and not in_boss_fight and street:
		start_boss_fight( [
			"Голоса из толпы:\nХа-ха-ха! Это так смешно!","Голоса из толпы:\nТы только посмотри на него!!",
		"Они все меня обсуждают... Точно меня...","Я - просто объект для насмешек, не более...",
		"Не могу... дышать..."
	])
	if position.x > 200 and not in_boss_fight and park:
		start_boss_fight( [
		"Какой же я жалкий...", "Даже другу пришлось меня успокаивать... Я обуза для всех...", 
		"Я абсолютно ничего из себя не представляю..."
	])
	if position.x > 550 and street and anxiety_rip and not flag:
		flag = true
		dialog_ui.start_dialog_with_choices(
		["Вы хотите пойти в парк?"], ["Да", "Нет"],
		func(choice_idx):               
			if choice_idx == 0:
				street = false
				park = true
				get_tree().change_scene_to_file(GameResources.scenes["park"])
				in_boss_fight = false
			else:
				pass
		)
	if position.x <=550 and flag:
		flag = false
	
func start_boss_fight(dialog):
	in_boss_fight = true
	DialogUI.dialog_finished.connect(_on_dialog_finished, CONNECT_ONE_SHOT)
	DialogUI.start_dialog(dialog)

func _on_dialog_finished():
	speed = 200
	boss_roar.play()
	var boss_scene = GameResources.load_scene("depression_boss" if park else "anxiety_boss")
	var boss = boss_scene.instantiate()
	if get_tree():
		get_tree().current_scene.add_child(boss)
	var dialog = ["О НЕТ... ЭТО ОПЯТЬ НАЧИНАЕТСЯ...!!!"]
	if street:
		boss.position = Vector2(550, 320)
		dialog = ["Тревожность переполняет меня....", "НЕТ! Я не дам тревожности победить"]
	else:
		boss.position = Vector2(300, 320)
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished
	
	boss.start_battle()
	
func end_boss_fight():
	in_boss_fight = false
	rain_music.start()
	get_tree().call_group("anxiety_projectiles", "queue_free")
	var boss = get_tree().get_first_node_in_group("anxiety_boss")
	if park:
		boss = get_tree().get_first_node_in_group("depression_boss")
	if boss:
		boss.end_battle()
