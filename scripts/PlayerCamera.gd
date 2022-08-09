extends Camera2D

var player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if len(player.cells) > 0:
		#position = position.linear_interpolate(player.cells[0].position, 10)
		position = player.cells[0].position
