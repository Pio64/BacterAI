class_name Highlighter
extends Node2D

"""The highlighter is a simple node 2d that draws a circle around it's parent
object (the agent body).
"""

var cell_position = Vector2(0,0)

func _ready() -> void:
	# set the name
	set_name("Highlighter_" + get_parent().name)
	# draw the circe, then hide it (otherwise every body would have a circle by default)
	update()
	hide()


func _process(delta):
	if !get_parent().is_dead:
		cell_position = get_parent().get_node("Cell").position
		update()


func _draw():
	"""Draw a circle around the parent node.
	"""
	draw_arc(cell_position,
			 Params.highlighter_radius,
			 0,
			 TAU,
			 Params.highlighter_radius / 2,
			 Params.highlighter_color,
			 Params.highlighter_width)
