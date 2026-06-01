extends Node

class_name GameResources

static var scenes = {
	"main": "res://scenes/main.tscn",
	"street": "res://scenes/street.tscn",
	"player": "res://scenes/player.tscn",
	"park": "res://scenes/park.tscn",
	"hospital": "res://scenes/hospital.tscn",
	"anxiety_boss": "res://scenes/anxiety_boss.tscn",
	"depression_boss": "res://scenes/depression_boss.tscn",
	"friend": "res://scenes/friend.tscn",
	"anxiety_projectile": "res://scenes/anxiety_projectile.tscn",
	"shop": "res://scenes/shop.tscn",
	"new_room": "res://scenes/new_room.tscn",
	"second_room": "res://scenes/second_room.tscn",
	"third_room": "res://scenes/third_room.tscn",
	"breathing_minigame": "res://scenes/breathing_minigame.tscn"
}

static func load_scene(scene_key: String) -> PackedScene:
		return load(scenes[scene_key])
