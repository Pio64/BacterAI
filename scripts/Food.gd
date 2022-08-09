extends Area2D

var radius = 10.0
var color


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
	update_sprite()
	update_collider()


func update_sprite():
	var sprite_scale = radius / 100
	$Sprite.scale = Vector2(sprite_scale, sprite_scale)
	$Sprite.modulate = color


func update_collider():
	var shape = CircleShape2D.new()
	shape.radius = radius / 2 # decrease the collider radius to make food easier to miss
	$CollisionShape2D.shape = shape


#func _on_Food_body_entered(body):
#	if body.is_in_group("Cell"):
#		body.add_radius(radius)
#		get_node("/root/Game").set_food_respawn(position)
#		queue_free()

func on_eaten():
	get_node("/root/Game").set_food_respawn(position)
	queue_free()
