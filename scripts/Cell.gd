extends KinematicBody2D

var player
var game
var radius = 0.0
var mass = 0.0
var velocity = Vector2()
var cell_scene = load("res://scenes/Cell.tscn")
var merge_time
#var last_ate_time = 0
var tracked_food = []
var tracked_cells = []

signal mass_gain(amount_gained)


# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_node("/root/Game")
	merge_time = calculate_merge_time(radius)
	#last_ate_time = Time.get_unix_time_from_system()

	# disable collisions with all cells except our player's cells
	#var cells = get_tree().get_nodes_in_group("Cell")
	#for cell in cells:
	#	if cell != self:
	#		if (player.has_method("get_cells") and player.cells.find(cell) == -1) or (!player.has_method("get_cells") and cell != player.cell):
	#			add_collision_exception_with(cell)


func _physics_process(_delta):
	# old movement code - works better when player can have multiple cells
	#var dir = Vector2()
	#dir = get_global_mouse_position() - global_position
	#var speed = game.PLAYER_SPEED / (radius / 100)
	##velocity = velocity.linear_interpolate(dir * speed, ACCELERATION * delta)
	#velocity = velocity.linear_interpolate(dir.clamped(speed), game.PLAYER_ACC * delta)

	#move_and_slide(velocity, Vector2.UP)

	# merge code
	#if merge_time > 0:
	#	merge_time -= delta
	#	if merge_time < 0:
	#		merge_time = 0
	#		if player.has_method("get_cells"):
	#			for cell in player.cells:
	#				if cell != self:
	#					add_collision_exception_with(cell)
	#		#elif player.cell != self:
	#		#	add_collision_exception_with(player.cell)
	for food in tracked_food:
		var dist = global_position.distance_to(food.global_position)
		if Global.covers_cell_enough(radius, food.radius, dist):
			add_mass(food.mass)
			food.on_eaten()

	for cell in tracked_cells:
		var dist = global_position.distance_to(cell.global_position)
		if Global.can_eat_cell(mass, cell.mass, radius, cell.radius, dist):
			add_mass(cell.mass)
			cell.queue_free()
			cell.player.cell_killed(cell, true)


func _draw():
	if !game.show_debug_lines:
		return

	var positions = get_circle(player.NUM_RAYS, 900)
	for i in range(0, len(positions)):
		if player.col_data[i][0] != -1:
			draw_line(Vector2(0, 0), positions[i], Color(1, 0, 0, 0.5))
		else:
			draw_line(Vector2(0, 0), positions[i], Color(0, 1, 0, 0.1))


func get_circle(steps: float, radius: float):
	var positions = []
	for step in steps:
		var circumferfenceProgress = float(step/steps)
		var currentRadian = circumferfenceProgress * 2 * PI
		var xScaled = cos(currentRadian)
		var yScaled = sin(currentRadian)

		var x = xScaled * radius
		var y = yScaled * radius
		var currentPosition = Vector2(x,y)

		positions.append(currentPosition)

	return positions


func update_sprite():
	var sprite_scale = radius / 100

	if is_inside_tree():
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property($Shape, "scale", Vector2(sprite_scale, sprite_scale), 0.1)
	else:
		$Shape.scale = Vector2(sprite_scale, sprite_scale)

	$Shape.self_modulate = player.color
	$Shape.z_index = radius
	$Shape/MassLabel.text = str(floor(mass))


func update_collider():
	var shape = CircleShape2D.new()
	shape.radius = radius
	#$CollisionShape2D.shape = shape
	$Area2D/CollisionShape2D.shape = shape


func add_mass(value):
	mass += value
	radius = Global.mass_to_radius(mass)
	update_sprite()
	update_collider()
	player.update_zoom_level()
	#last_ate_time = Time.get_unix_time_from_system()
	emit_signal("mass_gain", value)


# Cells lose mass over time, at a rate of 0.2% of their mass per second.
# This means that if you don't consume anything, you would lose half your mass in
# 5 minutes and 47 seconds. This also means that cells of certain size can no longer sustain their
# mass solely through pellets. They must instead consume other players' cells or viruses to maintain
# their size, or grow further. There is a setting to see the mass of your cell(s).
# https://agario.fandom.com/wiki/Cell
func mass_loss():
	mass /= 1.002
	radius = Global.mass_to_radius(mass)
	update_sprite()
	update_collider()
	player.update_zoom_level()


func split():
	if mass >= 35:
		print("split")
		mass /= 2
		radius = Global.mass_to_radius(mass)
		update_sprite()
		update_collider()

		var clone = cell_scene.instance()

		var mouse_pos = get_global_mouse_position()
		var dir = (mouse_pos - global_position) * 1000
		clone.mass = mass
		clone.radius = radius
		var speed = player.game.PLAYER_SPEED / (clone.radius / 3000)
		var vel = dir.clamped(speed + 1000)

		var new_player

		if player.has_method("get_cells"):
			clone.transform = transform
			clone.velocity = vel
			clone.player = player
			clone.update_sprite()
			clone.update_collider()
		else:
			new_player = game.ai_player_scene.instance()
			var default_cell = new_player.get_node("Cell")
			#new_player.remove_child(default_cell)
			#default_cell.queue_free()
			new_player.global_position = global_position
			default_cell.transform = transform
			default_cell.global_position = global_position
			default_cell.mass = mass
			default_cell.radius = radius
			default_cell.velocity = vel
			default_cell.player = new_player
			#clone.player = new_player
			#default_cell.update_sprite()
			#default_cell.update_collider()

		if player.has_method("get_cells"):
			player.add_child(clone)
			player.cells.append(clone)
			player.update_zoom_level()
		else:
			#new_player.add_child(clone)
			#new_player.cell = clone
			#clone.global_position = global_position
			game.ai_players.append(new_player)
			game.add_child(new_player)


# There is a cool down on merging cells together,
# meaning that a certain amount of time must pass before two cells
# are able to merge after splitting. The cool down time is
# calculated as 30 seconds plus 2.33% of the cells mass
# (e.g. if mass is 50, the cool down time is 31 seconds)
# https://agario.fandom.com/wiki/Splitting
func calculate_merge_time(cell_mass):
	return 30.0 + cell_mass * 0.0233


func _on_Area2D_area_entered(area):
	if area.is_in_group("Food"):
		tracked_food.append(area)
	else:
		var cell = area.get_parent()
		tracked_cells.append(cell)

func _on_Area2D_area_exited(area):
	if area.is_in_group("Food"):
		var index = tracked_food.find(area)
		tracked_food.remove(index)
	else:
		var cell = area.get_parent()
		var index = tracked_cells.find(cell)
		tracked_cells.remove(index)
