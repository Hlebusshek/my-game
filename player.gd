extends CharacterBody2D

@export var speed = 200
var screen_size
var player_size = Vector2(32, 32)
var near_bed = false
@onready var dialog_ui = DialogUI
@onready var prompt = InteractionPrompt
@onready var count_rip = rip_count
@onready var anxiety = preload("res://anxiety_boss.tscn").instantiate()
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
	if get_tree().current_scene.scene_file_path == "res://main.tscn":
		home = true
	if get_tree().current_scene.scene_file_path == "res://street.tscn":
		street = true
		home = false
	if get_tree().current_scene.scene_file_path == "res://park.tscn":
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
	var boss = get_tree().get_first_node_in_group("anxiety_boss")
	if park:
		boss = get_tree().get_first_node_in_group("depression_boss")
		count_rip.depression_rip_count += 1
		if count_rip.depression_rip_count == 3:
			boss.can_attack = false
			boss.fight_music.stop()
			var dialog1 = ["Я так больше не могу... Мне правда нужна помощь..."]
			DialogUI.start_dialog(dialog1)
			await DialogUI.dialog_finished
			phone_music.play()
			var dialog2 = ["*звонок телефона*",
			 "А-алло?..", "Голос из телефона:\nЗдравствуйте, это клиника 'Душевный баланс'.",
			"Голос из телефона:\nВы записаны на 15:00, ждём вас сегодня?", "...",
			"/Точно... Они смогут мне помочь.../", "/Я справлюсь!!/", "Да! Я обязательно приду! Скоро буду!" ]
			DialogUI.start_dialog(dialog2)
			await DialogUI.dialog_finished
			await fade_and_change_scene("res://hospital.tscn")
			return 
	boss.can_attack = false
	var dialog = ["Я чувствую себя нехорошо...", "Надо попробовать еще раз!"]
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished
	if get_tree():
		get_tree().reload_current_scene()
	boss.can_attack = true


func _process(delta):
	var closest_interactable = null
	var min_distance = INTERACTION_DISTANCE
	
	for interactable in get_tree().get_nodes_in_group("interactable"):
		var distance = global_position.distance_to(interactable.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_interactable = interactable

	if current_interactable != closest_interactable:
		if current_interactable:
			prompt.hide_prompt()
		
		current_interactable = closest_interactable
		
		if current_interactable:
			if current_interactable.has_method("get_interaction_text"):
				prompt.show_prompt(current_interactable.get_interaction_text())
			else:
				prompt.show_prompt()
			if current_interactable.has_method("show_dialog"):
				if Input.is_action_just_pressed("interact"):
					current_interactable.show_dialog()
	
	if Input.is_action_just_pressed("interact") and current_interactable:
		if is_instance_valid(current_interactable) and current_interactable.has_method("show_dialog"):
			current_interactable.show_dialog()
			
	if not is_instance_valid(dialog_ui):
		return
	if dialog_ui.is_dialog_active:
		return
		
		
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	else:
		pass
	position += velocity * delta
	position = position.clamp(
		Vector2(player_size.x/2, player_size.y/2), 
		Vector2(screen_size.x - player_size.x/2, screen_size.y - player_size.y/2))
	if abs(velocity.y)>0 or abs(velocity.x)>0:
		
		if velocity.x>0:
			$AnimatedSprite2D.play("walk_right")
		elif velocity.x<0:
			$AnimatedSprite2D.play("walk_left")
		elif velocity.y>0:
			$AnimatedSprite2D.play("walk_forward")
		elif velocity.y<0:
			$AnimatedSprite2D.play("walk_back")
	else:
		if $AnimatedSprite2D.animation == "walk_back":
			$AnimatedSprite2D.play("walk_back")
		else:
			$AnimatedSprite2D.play("walk_forward")

	move_and_slide()

func start_home_dialog_with_delay():
	if home and not home_dialog:
		home_dialog = true
		await get_tree().create_timer(1.0).timeout
		var dialog = [
			"Я не выходил из дома уже... даже не помню сколько недель...",
			"Каждый день - как тяжёлая ноша. Даже простые дела требуют невероятных усилий...",
			"Но... после месяцев мучений я всё же записался к психотерапевту.",
			"Сегодня день приёма.",
			"Может быть... просто может быть, мне хоть немного станет легче?",
			"У меня есть еще немного времени до выхода."
		]
		DialogUI.start_dialog(dialog)
		
func _physics_process(delta):
	if position.x > 200 and not in_boss_fight and street:
		start_boss_fight( [
			"Голоса из толпы:\nХа-ха-ха! Это так смешно!",
			"Голоса из толпы:\nТы только посмотри на него!!",
		"Они все меня обсуждают... Точно меня...",
		"Я - просто объект для насмешек, не более...",
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
		["Вы хотите пойти в парк?"],
		["Да", "Нет"],
		func(choice_idx):               
			if choice_idx == 0:
				street = false
				park = true
				get_tree().change_scene_to_file("res://park.tscn")
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
	var boss = preload("res://anxiety_boss.tscn").instantiate()
	if park:
		boss = preload("res://depression_boss.tscn").instantiate()
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
