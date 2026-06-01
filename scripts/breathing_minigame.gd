extends Node
signal minigame_finished(energy_restored: int)
@export var max_beats: int = 15
@export var target_scale: float = 0.38
@export var excellent_threshold: float = 0.12
@export var good_threshold: float = 0.25
@export var fast_probability: float = 0.7
@export var fast_min: float = 0.6
@export var fast_max: float = 1.0
@export var slow_min: float = 1.2
@export var slow_max: float = 1.6
const POINTS_EXCELLENT = 5
const POINTS_GOOD = 3
const POINTS_MISS = 0
@onready var shrink_ring = $Rings/ShrinkRing
@onready var center_ring = $Rings/CenterRing
@onready var judgment_label = $UI/JudgmentLabel
@onready var combo_label = $UI/ComboLabel
@onready var points_label = $UI/PointsLabel
@onready var instruction_label = $UI/InstructionLabel
@onready var beat_timer = $BeatTimer
@onready var music = $BreathingMusic
@onready var prompt = InteractionPrompt
var beat_count: int = 0
var combo: int = 0
var points: int = 0
var beat_start_ms: int = 0
var can_input: bool = false
var has_timed_out: bool = false
var current_tween: Tween
var start_scale_value: float = 1.0
var current_beat_duration: float = 1.0
var waiting_for_next: bool = false
var tween_finished_connected: bool = false

func _ready() -> void:
	music.play()
	prompt.hide_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if shrink_ring is Control:
		await ready
		shrink_ring.pivot_offset = shrink_ring.size / 2
	elif shrink_ring is Sprite2D:
		if shrink_ring.texture:
			shrink_ring.offset = Vector2(shrink_ring.texture.get_width() / 2, shrink_ring.texture.get_height() / 2)
	start_scale_value = shrink_ring.scale.x
	shrink_ring.visible = true
	shrink_ring.modulate.a = 1.0
	shrink_ring.scale = Vector2(start_scale_value, start_scale_value)
	points_label.text = "Очки: 0"
	_show_countdown()

func _show_countdown() -> void:
	instruction_label.text = "Дышите ровно... (3)"
	await get_tree().create_timer(1.0).timeout
	instruction_label.text = "Дышите ровно... (2)"
	await get_tree().create_timer(1.0).timeout
	instruction_label.text = "Дышите ровно... (1)"
	await get_tree().create_timer(1.0).timeout
	_start_beat()

func _start_beat() -> void:
	if beat_count >= max_beats:
		_finish()
		return
	if randf() < fast_probability:
		current_beat_duration = randf_range(fast_min, fast_max)
	else:
		current_beat_duration = randf_range(slow_min, slow_max)
	beat_count += 1
	can_input = true
	has_timed_out = false
	waiting_for_next = false
	beat_start_ms = Time.get_ticks_msec()
	instruction_label.text = "Нажми ПРОБЕЛ, когда круг совпадёт с центром!"
	if current_tween and current_tween.is_valid():
		if tween_finished_connected:
			current_tween.finished.disconnect(_on_tween_finished)
			tween_finished_connected = false
		current_tween.kill()
	shrink_ring.scale = Vector2(start_scale_value, start_scale_value)
	shrink_ring.modulate.a = 1.0
	shrink_ring.visible = true
	current_tween = create_tween()
	current_tween.tween_property(shrink_ring, "scale", Vector2.ZERO, current_beat_duration).set_ease(Tween.EASE_IN)
	current_tween.finished.connect(_on_tween_finished)
	tween_finished_connected = true
	beat_timer.wait_time = current_beat_duration + 0.1
	beat_timer.start()

func _on_tween_finished() -> void:
	if can_input and not waiting_for_next:
		can_input = false
		has_timed_out = true
		waiting_for_next = true
		beat_timer.stop()
		_points_and_judge("Miss", Color.RED, POINTS_MISS)
		combo = 0
		combo_label.text = "Комбо: x" + str(combo)
		points_label.text = "Очки: " + str(points)
		await _delay_and_next()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and can_input and not waiting_for_next:
		_check_hit()

func _check_hit() -> void:
	if not can_input or has_timed_out or waiting_for_next:
		return
	can_input = false
	waiting_for_next = true
	beat_timer.stop()
	if current_tween and current_tween.is_valid():
		if tween_finished_connected:
			current_tween.finished.disconnect(_on_tween_finished)
			tween_finished_connected = false
		current_tween.kill()
	var elapsed_sec = (Time.get_ticks_msec() - beat_start_ms) / 1000.0
	if elapsed_sec > current_beat_duration + 0.1:
		_points_and_judge("Miss", Color.RED, POINTS_MISS)
		combo = 0
		combo_label.text = "Комбо: x" + str(combo)
		points_label.text = "Очки: " + str(points)
		await _delay_and_next()
		return
	var progress = clamp(elapsed_sec / current_beat_duration, 0.0, 1.0)
	var current_scale = lerp(start_scale_value, 0.0, progress)
	var diff = abs(current_scale - target_scale)
	var excellent_limit = excellent_threshold * current_scale
	var good_limit = good_threshold * current_scale
	if diff <= excellent_limit:
		_points_and_judge("Excellent!", Color.LIME, POINTS_EXCELLENT)
		combo += 1
	elif diff <= good_limit:
		_points_and_judge("Good", Color.YELLOW, POINTS_GOOD)
		combo += 1
	else:
		_points_and_judge("Miss", Color.RED, POINTS_MISS)
		combo = 0
	combo_label.text = "Комбо: x" + str(combo)
	points_label.text = "Очки: " + str(points)
	await _delay_and_next()

func _delay_and_next() -> void:
	await get_tree().create_timer(0.5).timeout
	_start_beat()

func _points_and_judge(text: String, color: Color, points_gained: int) -> void:
	judgment_label.text = text
	judgment_label.modulate = color
	points += points_gained

func _on_beat_timer_timeout() -> void:
	if can_input and not has_timed_out and not waiting_for_next:
		can_input = false
		has_timed_out = true
		waiting_for_next = true
		if current_tween and current_tween.is_valid():
			if tween_finished_connected:
				current_tween.finished.disconnect(_on_tween_finished)
				tween_finished_connected = false
			current_tween.kill()
		_points_and_judge("Miss (поздно)", Color.RED, POINTS_MISS)
		combo = 0
		combo_label.text = "Комбо: x" + str(combo)
		points_label.text = "Очки: " + str(points)
		await _delay_and_next()

func _finish() -> void:
	var restored_energy: int
	if points < 60:
		restored_energy = int(points * 0.65)
	else:
		restored_energy = 40
	restored_energy = min(restored_energy, PlayerState.MAX_ENERGY - PlayerState.energy)
	PlayerState.energy = min(PlayerState.energy + restored_energy, PlayerState.MAX_ENERGY)
	instruction_label.text = "Восстановлено энергии: " + str(restored_energy)
	judgment_label.text = ""
	combo_label.text = ""
	await get_tree().create_timer(1.5).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("minigame_finished", restored_energy)
	queue_free()
