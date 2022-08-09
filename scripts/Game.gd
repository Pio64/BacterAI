extends Node2D

# Declare member variables here. Examples:
const FOOD_RESPAWN_TIME = 30
const MAP_SIZE = 8200
const PLAYER_SPEED = 20
const PLAYER_ACC = 3
const PLAYER_START_RADIUS = 25.0
const MASS_LOSS_TIMER = 1.0
export (PackedScene) var food_scene
export (PackedScene) var player_scene
var food_respawn_queue = []
var simulation_speed = 1
var cur_mass_loss_timer = MASS_LOSS_TIMER
var eat_check_time = 0
var show_debug_lines = false
var ga
var standalone_network
var standalone_ai_player

signal player_death(player_index)


# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.custom_network_name:
		start_wth_custom_network(Global.custom_network_name)
	else:
		start_new_simulation()


func start_new_simulation():
	ga = GeneticAlgorithm.new(37, 3, "res://scenes/AIPlayer.tscn", true, "custom")
	spawn_all_food()
	add_child(ga)
	spawn_all_ai()
	#spawn_player() # uncomment this if you want to play the game yourself


# when user loads existing network
func start_wth_custom_network(network_name):
	spawn_all_food()
	standalone_network = load("res://NEAT_usability/standalone_scripts/standalone_neuralnet.gd").new()
	standalone_network.load_config(network_name)
	standalone_ai_player = load("res://scenes/AIPlayer.tscn").instance()
	spawn_ai_player(standalone_ai_player)


# draw the grid
func _draw():
	var grid_color = Color(1, 1, 1, 0.025)
	var grid_cell_size = 50

	for line in range(0, MAP_SIZE):
		if line % grid_cell_size == 0:
			var start_pos = Vector2(0, line)
			var end_pos = Vector2(MAP_SIZE, line)
			draw_line(start_pos, end_pos, grid_color)

	for line in range(0, MAP_SIZE):
		if line % grid_cell_size == 0:
			var start_pos = Vector2(line, 0)
			var end_pos = Vector2(line, MAP_SIZE)
			draw_line(start_pos, end_pos, grid_color)


func _process(delta):
	if Input.is_action_just_pressed("increase_sim_speed"):
		simulation_speed += 1
	elif Input.is_action_just_pressed("decrease_sim_speed"):
		simulation_speed -= 1
		if simulation_speed < 1:
			simulation_speed = 1
	elif Input.is_action_just_pressed("reset_sim_speed"):
		simulation_speed = 1
	elif Input.is_action_just_pressed("toggle_debug_lines"):
		show_debug_lines = !show_debug_lines


func _physics_process(delta):
	if ga:
		ga.next_timestep()
	elif not standalone_ai_player.is_dead:
		var output = standalone_network.update(standalone_ai_player.sense())
		standalone_ai_player.act(output)

	cur_mass_loss_timer -= delta
	#if cur_mass_loss_timer <= 0:
	#	cur_mass_loss_timer = MASS_LOSS_TIMER
		#cell.mass_loss()
		#if cell.radius <= 10:
		#	cell.queue_free()
		#	cell.player.cell_killed(cell)

	if cur_mass_loss_timer <= 0:
		eat_check_time = OS.get_unix_time()

	var cells = get_tree().get_nodes_in_group("Cell")
	for cell in cells:
		if cur_mass_loss_timer <= 0:
			# kill cells if they haven't eaten in a while
			if eat_check_time - cell.last_ate_time >= 30:
				cell.queue_free()
				cell.player.cell_killed(cell)
				continue

		var dir = cell.player.movement_dir.normalized() * cell.player.movement_speed
		var speed = PLAYER_SPEED / (cell.radius / 3000)
		var velocity = cell.velocity.linear_interpolate(dir.clamped(speed), PLAYER_ACC * delta)
		cell.velocity = cell.move_and_slide(velocity, Vector2.UP)

		# block cells from going outside of the map
		if cell.global_position.x + cell.radius > MAP_SIZE:
			cell.global_position = Vector2(MAP_SIZE - cell.radius, cell.global_position.y)
		elif cell.global_position.x - cell.radius < 0:
			cell.global_position = Vector2(0 + cell.radius, cell.global_position.y)

		# block cells from going outside of the map
		if cell.global_position.y + cell.radius > MAP_SIZE:
			cell.global_position = Vector2(cell.global_position.x, MAP_SIZE - cell.radius)
		elif cell.global_position.y - cell.radius < 0:
			cell.global_position = Vector2(cell.global_position.x, 0 + cell.radius)

	if cur_mass_loss_timer <= 0:
		cur_mass_loss_timer = MASS_LOSS_TIMER

	if ga and ga.all_agents_dead:
		next_gen()


func spawn_all_food():
	var amount = MAP_SIZE / 6
	var points = []

	for i in range(0, amount):
		points.append(Vector2(rand_range(0, MAP_SIZE), rand_range(0, MAP_SIZE)))

	for point in points:
		spawn_food(point)


func spawn_food(pos):
	var item = food_scene.instance()
	item.position = pos
	add_child(item)


func set_food_respawn(pos):
	food_respawn_queue.append(pos)
	var timer = Timer.new()
	timer.wait_time = FOOD_RESPAWN_TIME
	timer.connect("timeout", self, "food_respawn")
	timer.one_shot = true
	add_child(timer)
	timer.start()


func food_respawn():
	if len(food_respawn_queue) > 0:
		spawn_food(food_respawn_queue[0])
		food_respawn_queue.pop_front()


func spawn_player():
	var player = player_scene.instance()
	var x = rand_range(0, MAP_SIZE)
	var y = rand_range(0, MAP_SIZE)
	player.position = Vector2(x, y)
	player.get_node("Cell").player = player
	add_child(player)


func spawn_all_ai():
	for body in ga.get_curr_bodies():
		spawn_ai_player(body)


func spawn_ai_player(ai_player):
	var x = rand_range(0, MAP_SIZE)
	var y = rand_range(0, MAP_SIZE)
	ai_player.position = Vector2(x, y)
	ai_player.get_node("Cell").player = ai_player
	add_child(ai_player)


func circle_contains_circle(r1, r2, distance):
	if r1 > (r2 + distance):
		return true
	else:
		return false


func _on_GenerationTimer_timeout():
	next_gen()


func next_gen():
	ga.evaluate_generation()
	ga.next_generation()

	for player in get_tree().get_nodes_in_group("Player"):
		player.queue_free()

	spawn_all_ai() # respawn AI