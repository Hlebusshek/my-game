extends Node
@onready var black_bg = $CanvasLayer/BlackBackground
@onready var label = $CanvasLayer/Label
@onready var music = $Music
@onready var prompt = InteractionPrompt

func _ready() -> void:
	music.play()
	prompt.hide_prompt()
	await get_tree().create_timer(1.0).timeout
	var dialog1 = [
		"Психотерапевт:\nЗдравствуйте! Расскажите, что вас привело ко мне сегодня?",
		"Здравствуйте... Последние месяцы у меня совсем нет сил..."
	]
	DialogUI.start_dialog(dialog1)
	await DialogUI.dialog_finished
	await show_time_skip("Прошел 1 месяц...")
	get_tree().change_scene_to_file(GameResources.scenes["new_room"])

func show_time_skip(message: String) -> void:
	black_bg.visible = true
	label.visible = true
	black_bg.modulate.a = 0
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(black_bg, "modulate:a", 1.0, 1.0)
	await tween.finished
	label.text = message
	var fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 1.0, 1.0)
	await fade_tween.finished
	await get_tree().create_timer(2.5).timeout
	fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.8)
	
func _process(_delta: float) -> void:
	pass
