extends Node

var energy: int = 50
const MAX_ENERGY: int = 100
var has_tomato_paste: bool = false
var last_choice_type: String = ""
var choice_score: int = 0
var has_watered_cactus: bool = false
var has_drunk_cocoa: bool = false

func reset_all() -> void:
	energy = 50
	has_tomato_paste = false
	last_choice_type = ""
	choice_score = 0
	has_watered_cactus = false
	has_drunk_cocoa = false
