extends CharacterBody2D

@export var speed = 200
var screen_size
var player_size = Vector2(32, 32)
var near_bed = false
@onready var dialog_ui = DialogUI
@onready var prompt = InteractionPrompt
@onready var anxiety = preload("res://anxiety_boss.tscn").instantiate()
var current_interactable: Node = null
const INTERACTION_DISTANCE = 40
var in_boss_fight: bool = false
var health: int = 3
var street: bool = false


func _ready():
	$Area2D.connect("area_entered", _on_area_entered)
	add_to_group("player")
	if get_tree().current_scene.scene_file_path == "res://street.tscn":
		street = true
	screen_size = get_viewport_rect().size
	self.collision_mask = 1
	position.x = 250
	position.y = 300

func _on_area_entered(area):
	if area.is_in_group("enemy_projectile"):
		take_damage(1)
		area.queue_free()
		
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		game_over()

func game_over():
	anxiety.end_battle()
	var dialog = ["Я чувствую себя нехорошо...", "Надо попробовать еще раз!"]
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished
	get_tree().reload_current_scene()

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
		if current_interactable.has_method("show_dialog"):
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
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	position += velocity * delta
	position = position.clamp(
		Vector2(player_size.x/2, player_size.y/2), 
		Vector2(screen_size.x - player_size.x/2, screen_size.y - player_size.y/2))
	if velocity.x != 0 or velocity.y !=0:
		$AnimatedSprite2D.animation = "walk"
	move_and_slide()


func _physics_process(delta):
	if position.x > 200 and not in_boss_fight and street:
		start_boss_fight()
	
func start_boss_fight():
	in_boss_fight = true
	
	var dialog = [
		"Что это?.. Моя тревожность материализовалась!",
		"Я должен успокоиться..."
	]
	DialogUI.dialog_finished.connect(_on_dialog_finished, CONNECT_ONE_SHOT)
	DialogUI.start_dialog(dialog)

func _on_dialog_finished():
	speed = 200
	var boss = preload("res://anxiety_boss.tscn").instantiate()
	get_parent().add_child(boss)
	boss.position = Vector2(550, 320)
	var dialog = ["Тревожность атакует!", "Нужно защищаться!"]
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished
	
	boss.start_battle(self)
	
func end_boss_fight():
	in_boss_fight = false
	get_tree().call_group("anxiety_projectiles", "queue_free")
	var boss = get_tree().get_first_node_in_group("anxiety_boss")
	if boss:
		boss.end_battle()
	
	#var friend = preload("res://Friend.tscn").instantiate()
	#friend.position = Vector2(400, 350)
	#add_sibling(friend)
