extends Node
@onready var black_bg = $CanvasLayer/BlackBackground 
@onready var label = $CanvasLayer/Label 
@onready var music = $Music
@onready var prompt = InteractionPrompt

var credits = [
	"Спустя месяц терапии...\nЯ начал замечать маленькие радости в жизни",
	"Через 3 месяца...\nСтало легче вставать по утрам",
	"Полгода спустя...\nЯ снова начал встречаться с друзьями",
	"Год терапии...\nДепрессия больше не контролирует мою жизнь",
	"Сейчас...\nЯ научился справляться с трудностями\nи ценить каждый день",
	"Следите за вашим здоровьем\nи цените жизнь!\nСпасибо за прохождение!"
]

var current_credit = 0

func _ready() -> void:
	music.play()
	prompt.hide_prompt()
	await get_tree().create_timer(2.0).timeout
	var dialog1 = [
		"Психотерапевт:\nЗдравствуйте! Расскажите, что вас привело ко мне сегодня?",
		"Здравствуйте... Последние месяцы у меня совсем нет сил..."
	]
	DialogUI.start_dialog(dialog1)
	await DialogUI.dialog_finished
	
	await start_credits()

	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://main.tscn")


func start_credits():
	black_bg.visible = true
	label.visible = true
	black_bg.modulate.a = 0
	label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(black_bg, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	for credit in credits:
		label.text = credit
		var fade_tween = create_tween()
		fade_tween.tween_property(label, "modulate:a", 1.0, 1.0)
		await fade_tween.finished
		await get_tree().create_timer(3.0).timeout
		
		fade_tween = create_tween()
		fade_tween.tween_property(label, "modulate:a", 0.0, 0.5)
		await fade_tween.finished

func _process(delta: float) -> void:
	pass
