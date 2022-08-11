extends Node


# Declare member variables here. Examples:
var custom_network_name = null


func _ready():
	randomize()


func can_eat_cell(m1, m2, r1, r2, distance):
	# has 25% more mass
	if m1 < m2 * 1.25:
		return false

	return covers_cell_enough(r1, r2, distance)


func covers_cell_enough(r1, r2, distance):
	# covers 75% of another circle
	if r1 > ((r2 / 2) + distance):
		return true
	else:
		return false


# calculates radius from mass
func mass_to_radius(mass):
	return sqrt(mass) * 10.2


func rand_color():
	return Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
