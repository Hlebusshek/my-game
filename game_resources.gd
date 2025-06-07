extends Node

class_name GameResources

static var scenes = {
	"main": "res://main.tscn",
	"street": "res://street.tscn",
	"player": "res://player.tscn",
	"park": "res://park.tscn",
	"hospital": "res://hospital.tscn",
	"menu": "res://Menu.tscn",
	"anxiety_boss": "res://anxiety_boss.tscn",
	"depression_boss": "res://depression_boss.tscn",
	"friend": "res://friend.tscn",
	"anxiety_projectile": "res://anxiety_projectile.tscn"
}

static func load_scene(scene_key: String) -> PackedScene:
		return load(scenes[scene_key])
