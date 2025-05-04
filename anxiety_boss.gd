extends CharacterBody2D

var projectile_scene = preload("res://anxiety_projectile.tscn")
@export var fire_rate: float = 0.5
@export var projectile_count: int = 12
@export var start_delay: float = 0.5

var can_attack: bool = false
var current_pattern: String = "circle"
var attack_angle: float = 0.0
@export var spread_angle: float = 0.2
@onready var attack_timer: Timer = $AttackTimer
@onready var pattern_timer: Timer = $PatternTimer

func _ready() -> void:
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	pattern_timer.connect("timeout", _on_pattern_timer_timeout)

func start_battle(player: Node):
	await get_tree().create_timer(start_delay).timeout 
	can_attack = true
	attack_timer.wait_time = fire_rate
	pattern_timer.wait_time = 0.2
	attack_timer.start()
	pattern_timer.start()
	
func spawn_projectile(base_angle: float):
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_transform = Transform2D.IDENTITY
	projectile.rotation = 0
	projectile.scale = Vector2.ONE
	projectile.global_position = Vector2(550, 320)
	projectile.position = Vector2(550, 320)
	projectile.force_update_transform()
	var random_spread = randf_range(-spread_angle, spread_angle)
	var final_angle = base_angle + random_spread
	projectile.direction = Vector2(cos(final_angle), sin(final_angle)).normalized()
	projectile.rotation = final_angle

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

func end_battle():
	can_attack = false
	attack_timer.stop()
	pattern_timer.stop()
	queue_free()
	
func _on_pattern_timer_timeout():
	var patterns = ["circle", "spiral", "random"]
	current_pattern = patterns[randi() % patterns.size()]
