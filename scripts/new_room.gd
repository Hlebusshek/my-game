extends Node
@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var room_music = $RoomMusic

func _ready() -> void:
	prompt.hide_prompt()
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
	player.position = Vector2(300, 300)
	player.speed = 200
	if room_music:
		room_music.play()
	await get_tree().create_timer(0.5).timeout
	var dialog = [
		"Спустя месяц терапии... Мир вокруг уже не кажется таким плохим.",
		"Я начал замечать мелочи, которые раньше просто пропускал.",
		"Прежде чем выйти... Может, стоит просто осмотреться?", 
		"В комнате наверняка есть что-то, что поможет мне набраться сил."
	]
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished
	prompt.hide_prompt()

func _process(_delta: float) -> void:
	pass
