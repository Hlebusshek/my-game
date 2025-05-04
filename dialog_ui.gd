extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/Label
@onready var choice_container = $Panel/ChoiceContainer
@onready var choice_button =  $Button

var current_dialogue = []
var current_choices = []
var current_line = 0
var is_dialog_active = false
var choice_callback = null

signal dialog_finished

func _ready() -> void:
	hide_dialog()
	choice_button.hide()


func _process(delta: float) -> void:
	pass


func start_dialog(lines: Array):
	if is_dialog_active: 
		return
	show()
	current_dialogue = lines
	current_line = 0
	is_dialog_active = true
	_show_current_line()
	set_process_input(true)
	
func start_dialog_with_choices(lines: Array, choices: Array, callback: Callable):
	if is_dialog_active:
		return
	
	show()
	current_dialogue = lines
	current_choices = choices
	current_line = 0
	is_dialog_active = true
	choice_callback = callback
	_show_current_line()

func _show_current_line():
	if current_line < current_dialogue.size():
		label.text = current_dialogue[current_line]
		panel.show()
		if current_line == current_dialogue.size() - 1 && !current_choices.is_empty():
			_show_choices()
	else:
		end_dialogue()

func clear_choices():
	for child in choice_container.get_children():
		child.queue_free()
	choice_container.hide()
	
func _show_choices():
	for child in choice_container.get_children():
		child.queue_free()
	for i in range(current_choices.size()):
		var button = choice_button.duplicate()
		button.show()
		button.custom_minimum_size = choice_button.size
		button.size_flags_stretch_ratio = 0
		button.text = current_choices[i]
		button.pressed.connect(_on_choice_selected.bind(i))
		button.pressed.connect(
			func():
				clear_choices()
		)
		choice_container.add_child(button)

func _on_choice_selected(choice_index: int):
	if choice_callback:
		choice_callback.call(choice_index)
	end_dialogue()

func end_dialogue():
	hide()
	is_dialog_active = false
	set_process_input(false)
	emit_signal("dialog_finished")

func hide_dialog():
	panel.hide()
	label.text = ""
	for child in choice_container.get_children():
		child.queue_free()

func _input(event):
	if is_dialog_active and (event is InputEventKey and event.is_action_pressed("ui_accept")):
		if event.is_pressed() and not event.is_echo():
			current_line += 1
			_show_current_line()
