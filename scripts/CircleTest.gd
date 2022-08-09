extends Node2D

func _draw():
	draw_circle(Vector2(0,0), 500, Color(0,0,0,0.1))
	var positions = GetCircle(16, 500)
	for pos in positions:
		draw_line(Vector2(0,0), pos, Color(0,1,0))
		
	


func GetCircle(steps : float,radius : float):
	var positions = []
	for step in steps:
		var circumferfenceProgress = float(step/steps)
		var currentRadian = circumferfenceProgress * 2 * PI
		var xScaled = cos(currentRadian)
		var yScaled = sin(currentRadian)
		
		var x = xScaled * radius
		var y = yScaled * radius
		
		var currentPosition = Vector2(x,y)
		
		#print(currentPosition)
		var raycast = RayCast2D.new()
		raycast.cast_to = currentPosition
		self.add_child(raycast)
		positions.append(currentPosition)
	return positions
		
		
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	GetCircle(16, 500)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
