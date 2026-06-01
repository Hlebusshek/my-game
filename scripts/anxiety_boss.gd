extends CharacterBody2D

var projectile_scene = GameResources.load_scene("anxiety_projectile")
@export var fire_rate: float = 0.5
@export var projectile_count: int = 12
@export var start_delay: float = 0.5

var can_attack: bool = false
var current_pattern: String = "circle"
var attack_angle: float = 0.0
@export var spread_angle: float = 0.2
@onready var attack_timer: Timer = $AttackTimer
@onready var pattern_timer: Timer = $PatternTimer
@onready var prompt = InteractionPrompt
@onready var fight_music = $Fight
@onready var rain_music = get_node("/root/Street/RainMusic")
var friend_spawn_timer: Timer
var friend_instance = null
var current_interactable: Node = null
const INTERACTION_DISTANCE = 40
var interacting_friend = null

func _ready() -> void:
	add_to_group("anxiety_boss")
	set_collision_layer_value(3, true)
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	pattern_timer.connect("timeout", _on_pattern_timer_timeout)
	friend_spawn_timer = Timer.new()
	friend_spawn_timer.wait_time = 17.0
	friend_spawn_timer.one_shot = true
	friend_spawn_timer.timeout.connect(_on_friend_spawn_timer_timeout)
	add_child(friend_spawn_timer)

func start_battle():
	await get_tree().create_timer(start_delay).timeout
	rain_music.stop()
	fight_music.play()
	can_attack = true
	attack_timer.wait_time = fire_rate
	attack_timer.start()
	friend_spawn_timer.start()
	
func _on_friend_spawn_timer_timeout():
	if not can_attack:
		return
		
	friend_instance = GameResources.load_scene("friend").instantiate()
	get_parent().add_child(friend_instance)
	friend_instance.position = Vector2(50, 450)
	friend_instance.add_to_group("friend")
	friend_instance.add_to_group("interactable")
	
func spawn_projectile(base_angle: float):
	var projectile = projectile_scene.instantiate()
	add_child(projectile)
	projectile.set_deferred("monitoring", false)
	await get_tree().create_timer(0.05).timeout
	projectile.set_deferred("monitoring", true)
	projectile.position = Vector2.ZERO
	projectile.set_collision_mask_value(2, false)  
	var random_spread = randf_range(-spread_angle, spread_angle)
	var final_angle = base_angle + random_spread
	projectile.direction = Vector2(cos(final_angle), sin(final_angle)).normalized()
	projectile.rotation = final_angle
	projectile.global_position = self.global_position
	await get_tree().process_frame
	projectile.set_collision_mask_value(2, true)

func _start_attacks():
	can_attack = true
	$AttackTimer.start()
	$PatternTimer.start()

func _on_attack_timer_timeout():
	if can_attack:
		match current_pattern:
			"circle":
				fire_circle()
			"spiral":
				fire_spiral()
			"random":
				fire_random()

func fire_circle():
	for i in range(projectile_count):
		var base_angle = i * (2 * PI / projectile_count)
		spawn_projectile(base_angle)

func fire_spiral():
	for i in range(projectile_count):
		var base_angle = attack_angle + i * (2 * PI / projectile_count)
		spawn_projectile(base_angle)
	attack_angle += 0.3

func fire_random():
	for i in range(projectile_count):
		var base_angle = randf_range(0, 2 * PI)
		spawn_projectile(base_angle)
		
func preend_battle():
	fight_music.stop()
	self.can_attack = false
	if is_instance_valid(self.attack_timer):
		self.attack_timer.stop()
		self.attack_timer.queue_free()
		self.attack_timer = null
	if is_instance_valid(self.pattern_timer):
		self.pattern_timer.stop()
		self.pattern_timer.queue_free()
		self.pattern_timer = null
	if is_instance_valid(self.friend_spawn_timer):
		self.friend_spawn_timer.stop()
		self.friend_spawn_timer.queue_free()
		self.friend_spawn_timer = null
	get_tree().call_group("anxiety_projectiles", "queue_free")


func end_battle():
	preend_battle()
	rain_music.play()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.connect("finished", Callable(self, "_on_fade_out_finished"))
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.anxiety_rip = true

func _on_fade_out_finished():
	queue_free()
	
func _on_pattern_timer_timeout():
	var patterns = ["circle", "spiral", "random"]
	current_pattern = patterns[randi() % patterns.size()]

func _process(_delta):
	update_interactable_prompt()
	handle_interaction()

func update_interactable_prompt():
	var closest = get_closest_interactable()
	if current_interactable != closest:
		if current_interactable:
			prompt.hide_prompt()
		current_interactable = closest
		show_current_prompt()

func get_closest_interactable():
	var closest = null
	var min_dist = INTERACTION_DISTANCE
	for interactable in get_tree().get_nodes_in_group("interactable"):
		var dist = global_position.distance_to(interactable.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = interactable
	return closest

func show_current_prompt():
	if current_interactable:
		var text = current_interactable.get_interaction_text() if current_interactable.has_method("get_interaction_text") else ""
		prompt.show_prompt(text)

func handle_interaction():
	if Input.is_action_just_pressed("interact") and current_interactable:
		if current_interactable.is_in_group("friend"):
			clear_projectiles()
			interacting_friend = current_interactable
			if current_interactable.has_method("show_dialog"):
				current_interactable.show_dialog()
				
func clear_projectiles():
	get_tree().call_group("anxiety_projectiles", "queue_free")
