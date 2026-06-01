extends Area2D

var speed = 200
var direction = Vector2.RIGHT
var damage = 1
var can_collide = false

func _ready():
	set_collision_mask_value(3, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(2, false)
	await get_tree().create_timer(0.1).timeout
	can_collide = true
	set_collision_mask_value(2, true)
	
	$LifeTimer.start(4.0)
	connect("body_entered", _on_body_entered)
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, false)
	
	global_position = get_parent().global_position

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if !can_collide: 
		return
		
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()

func _on_life_timer_timeout():
	queue_free()
