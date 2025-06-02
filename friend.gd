extends Area2D

var dialog_ui = DialogUI
@onready var friend_music = $FriendMusic
@onready var magic_music = $Magic
@onready var fight_music = get_node("/root/AnxietyBoss/Fight")

func _ready():
	add_to_group("interactable")
	magic_music.play()
	

func show_dialog():
	friend_music.play()
	var boss = get_tree().get_first_node_in_group("anxiety_boss")
	if boss and boss.has_method("preend_battle"):
		boss.preend_battle()
		
	var dialog = ["Друг:\nТы справишься!\nЯ ВЕРЮ в тебя!",
	"Друг:\nТы уже проходил через это раньше!","Но они все обсуждают меня!!",
	"Друг:\nОни заняты своими делами... Видишь? Никто не смотрит.",
	"Друг:\nА если кто-то и обсуждает тебя...",
	"Друг:\n...разве так важно мнение тех, кого ты больше никогда не увидишь?",
	"А ведь ты прав...",
	"Спасибо, друг, ты всегда появляешься тогда, когда так мне нужен!",
	"Теперь я могу идти дальше!"]
	dialog_ui.dialog_finished.connect(_on_dialog_finished, CONNECT_ONE_SHOT)
	dialog_ui.start_dialog(dialog)

func _on_dialog_finished():
	var boss = get_tree().get_first_node_in_group("anxiety_boss")
	if boss:
		boss.end_battle()
	queue_free()
