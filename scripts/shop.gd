extends Node
@onready var player_scene = GameResources.load_scene("player")
@onready var prompt = InteractionPrompt
@onready var shop_music = $ShopMusic
@onready var black_bg = $CanvasLayer/BlackBackground
@onready var skip_label = $CanvasLayer/Label

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
	player.scale = Vector2(2, 2)
	player.position = Vector2(30, 400)
	player.speed = 200
	if shop_music:
		shop_music.play()
	await get_tree().create_timer(0.5).timeout
	var dialog = [
		"Так... Я в магазине.",
		"Надо купить томатную пасту."
	]
	DialogUI.start_dialog(dialog)
	await DialogUI.dialog_finished

func go_to_next_location():
	if black_bg and skip_label:
		black_bg.visible = true
		skip_label.visible = true
		black_bg.modulate.a = 0
		skip_label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(black_bg, "modulate:a", 1.0, 1.0)
		await tween.finished
		skip_label.text = "Прошло 3 месяца..."
		var fade_tween = create_tween()
		fade_tween.tween_property(skip_label, "modulate:a", 1.0, 1.0)
		await fade_tween.finished
		await get_tree().create_timer(2.5).timeout
		fade_tween = create_tween()
		fade_tween.tween_property(skip_label, "modulate:a", 0.0, 0.8)
		await fade_tween.finished
	get_tree().change_scene_to_file(GameResources.scenes["second_room"])
	
func _process(_delta: float) -> void:
	pass
