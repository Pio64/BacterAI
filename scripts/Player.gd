extends Node2D

const NUM_RAYS = 16 # number of raycasts
var color
var cells = []
var game
var movement_dir = Vector2.ZERO
var movement_speed = 1.0
var rays = []
var col_data = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	game = get_node("/root/Game")

	for i in range(0, NUM_RAYS):
		rays.append($Cell.get_node("Ray" + str(i)))

	for i in range(0, NUM_RAYS):
		col_data.append([-1, -1])

	color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
	$Cell.player = self
	$Cell.radius = game.PLAYER_START_RADIUS
	$Cell.update_sprite()
	$Cell.update_collider()
	cells.append($Cell)
	$Camera2D.player = self
	update_zoom_level()


func _physics_process(delta):
	var mouse_pos = get_global_mouse_position()
	for cell in cells:
		movement_dir = mouse_pos - cell.global_position
		movement_speed = movement_dir.length()
		#var speed = game.PLAYER_SPEED / (cell.radius / 3000)
		#cell.velocity = cell.velocity.linear_interpolate(dir.clamped(speed), game.PLAYER_ACC * delta)
		#cell.move_and_slide(cell.velocity, Vector2.UP)

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


func _process(delta):
	for cell in cells:
		cell.update()

	var amount_cells = cells.size()

	if Input.is_action_just_pressed("ui_accept") and amount_cells < 16:
		for i in range(0, amount_cells):
			if cells.size() >= 16:
				break
			cells[i].split()


func update_zoom_level():
	#$Camera2D.zoom = Vector2($Camera2D.zoom.x + (radius / 50000), $Camera2D.zoom.y + (radius / 50000))
	var radius = 0.0
	var total_area = 0.0
	for cell in cells:
		var cell_area = PI * pow(cell.radius, 2)
		total_area += cell_area

	radius = sqrt(total_area / PI)
	var zoom = 0.5 + (radius / 64)
	$Camera2D.zoom = Vector2(zoom, zoom)


func cell_killed(cell):
	print("cell killed")
	var index = cells.find(cell)
	if index > -1:
		cells.remove(index)

	if len(cells) == 0:
		queue_free()


func get_cells():
	return cells
