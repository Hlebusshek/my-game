extends Node

@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var rain_music = $RainMusic
@onready var knock_sound = $KnockSound
@onready var door_node = $Door
@onready var sister_sprite = $Sister
@onready var bg_room = $Room
@onready var bg_room_low = $RoomLow
@onready var black_bg = $CanvasLayer/BlackBackground
@onready var skip_label = $CanvasLayer/Label
@onready var doorbell_music = $Doorbell
@onready var room1_music = $RoomMusic
@onready var room2_music = $RoomMusic2
@onready var breathe_button: Button = $BreatheButton
var has_knocked = false

func _ready() -> void:
	_update_room_background()
	prompt.hide_prompt()
	if breathe_button: 
		breathe_button.visible = false
	var player = player_scene.instantiate()
	add_child(player)
	await get_tree().process_frame
	var heart_icon = player.get_node_or_null("PlayerUI/HeartIcon")
	var health_label = player.get_node_or_null("PlayerUI/HealthLabel")
	if heart_icon: heart_icon.hide()
	if health_label: health_label.hide()
	player.show()
	player.set_process(true)
	player.set_physics_process(true)
	player.position = Vector2(250, 300)
	player.scale = Vector2(2, 2) 
	player.speed = 200
	if rain_music:
		rain_music.play()
	if door_node:
		door_node.remove_from_group("interactable")
	if sister_sprite:
		sister_sprite.visible = false
	await get_tree().create_timer(0.5).timeout
	var opening_dialog = []
	if PlayerState.energy < 50:
		opening_dialog = [
			"Три месяца терапии... Но сил всё ещё мало.",
			"Я чувствую постоянную усталость, но продолжаю бороться."
		]
	else:
		opening_dialog = [
			"Три месяца терапии... Кажется, я начинаю чувствовать прилив сил.",
			"Раньше было намного хуже. Я двигаюсь вперёд."
		]
	DialogUI.start_dialog(opening_dialog)
	await DialogUI.dialog_finished
	await get_tree().create_timer(15.0).timeout
	_trigger_knock_event()

func _update_room_background() -> void:
	var is_low_score = PlayerState.choice_score <= 4
	if bg_room: bg_room.visible = !is_low_score
	if bg_room_low: bg_room_low.visible = is_low_score
	if !is_low_score:
		room2_music.play()
	else:
		room1_music.play()

func _trigger_knock_event():
	if has_knocked or not door_node: return
	has_knocked = true
	if knock_sound: knock_sound.play()
	door_node.add_to_group("interactable")
	doorbell_music.play()
	room1_music.stop()
	room2_music.stop()
	DialogUI.start_dialog(["*Звонок в дверь*"])

func reveal_sister():
	if not sister_sprite or sister_sprite.visible: return
	sister_sprite.visible = true
	sister_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(sister_sprite, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)

func go_to_next_location() -> void:
	if not black_bg or not skip_label:
		get_tree().change_scene_to_file(GameResources.scenes["third_room"])
		return
	black_bg.visible = true
	skip_label.visible = true
	black_bg.modulate.a = 0.0
	skip_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(black_bg, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	skip_label.text = "Прошло полгода..."
	var fade_tween = create_tween()
	fade_tween.tween_property(skip_label, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	await fade_tween.finished
	await get_tree().create_timer(2.5).timeout
	fade_tween = create_tween()
	fade_tween.tween_property(skip_label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN_OUT)
	await fade_tween.finished
	get_tree().change_scene_to_file(GameResources.scenes["third_room"])
