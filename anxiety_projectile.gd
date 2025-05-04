extends Area2D

var speed = 200
var direction = Vector2.RIGHT
var damage = 1

func _ready():
	#await get_tree().create_timer(0.05).timeout
	position = Vector2(550, 320)
	$LifeTimer.start(4.0)
	connect("body_entered", _on_body_entered)
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, false)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()

func _on_life_timer_timeout():
	queue_free()
