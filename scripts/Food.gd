extends Area2D

var mass = 1.0
var radius = 0.0
var color


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	color = Global.rand_color()
	radius = Global.mass_to_radius(mass)
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


func on_eaten():
	get_node("/root/Game").set_food_respawn(position)
	queue_free()
