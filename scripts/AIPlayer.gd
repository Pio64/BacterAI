extends Node2D

const NUM_RAYS = 16 # number of raycasts
var color
var cell
var game
var movement_dir = Vector2.ZERO#(get_viewport().size.x / 2, get_viewport().size.y / 2)
var movement_speed = 0.0
var split_pressed = false
var start_radius = 0
var rays = []
var col_data = []
var fitness = 0.0
var is_dead = false

signal death


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	movement_dir = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	game = get_node("/root/Game")

	for i in range(0, NUM_RAYS):
		rays.append($Cell.get_node("Ray" + str(i)))

	for i in range(0, NUM_RAYS):
		col_data.append([-1, -1])

	if start_radius == 0:
		start_radius = game.PLAYER_START_RADIUS

	color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
	$Cell.radius = start_radius
	$Cell.update_sprite()
	$Cell.update_collider()
	cell = $Cell

	cell.connect("radius_gain", self, "_cell_gained_radius")


func _physics_process(delta):
	if is_dead:
		return

	if split_pressed:
		split_pressed = false
		cell.split()


# passes inputs to the neural network - called by GeneticAlgorithm
func sense() -> Array:
	var velocity_dir = cell.velocity.normalized()
	var velocity_length = cell.velocity.length()

	for i in range(0, len(rays)):
		rays[i].force_raycast_update()

		var col = rays[i].get_collider()
		if col:
			col_data[i][0] = global_position.distance_to(rays[i].get_collision_point()) / 2000

			if !col.is_in_group("Food") and !col.is_in_group("Cell") and !col.is_in_group("Wall"):
				col = col.get_parent()

			col_data[i][1] = col.radius / 1000
		else:
			col_data[i][0] = -1
			col_data[i][1] -1

	cell.update()

	var contains_object = len(cell.tracked_food) > 0 || len(cell.tracked_cells) > 0
	#var contains_smaller_object = len(cell.tracked_food) > 0

	#if !contains_smaller_object:
	#	for c in cell.tracked_cells:
	#		if c.radius < cell.radius:
	#			contains_smaller_object = true
	#			break

	#if contains_smaller_object:
	#	fitness += 1

	return [
		velocity_dir.x,
		velocity_dir.y,
		velocity_length / 1000,
		cell.radius / 1000,
		int(contains_object),
		col_data[0][0], col_data[0][1],
		col_data[1][0], col_data[1][1],
		col_data[2][0], col_data[2][1],
		col_data[3][0], col_data[3][1],
		col_data[4][0], col_data[4][1],
		col_data[5][0], col_data[5][1],
		col_data[6][0], col_data[6][1],
		col_data[7][0], col_data[7][1],
		col_data[8][0], col_data[8][1],
		col_data[9][0], col_data[9][1],
		col_data[10][0], col_data[10][1],
		col_data[11][0], col_data[11][1],
		col_data[12][0], col_data[12][1],
		col_data[13][0], col_data[13][1],
		col_data[14][0], col_data[14][1],
		col_data[15][0], col_data[15][1]
	]


# get output from the neural network and do something with it - called by GeneticAlgorithm
func act(output: Array) -> void:
	movement_dir = Vector2(output[0], output[1])
	movement_speed = output[2] * 960
	#split_pressed = output[3] > 0.5


# get agent's fitness score - called by GeneticAlgorithm
func get_fitness() -> float:
	if fitness < 0:
		return 0.0
	return fitness


func cell_killed(cell, was_eaten=false):
	#print("cell killed")
	is_dead = true

	#if was_eaten:
	#	fitness -= 10

	emit_signal("death") # needed for GeneticAlgorithm


func _cell_gained_radius(amount):
	fitness = cell.radius


func update_zoom_level():
	pass
