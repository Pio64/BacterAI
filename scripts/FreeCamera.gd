extends Camera2D


# Declare member variables here. Examples:
var is_panning = false
const ZOOM_SENS = 0.5


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	is_panning = Input.is_action_pressed("camera_pan")


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == 5: # Scroll Down
				zoom.x += ZOOM_SENS
				zoom.y += ZOOM_SENS 
			if event.button_index == 4: # Scroll Up
				zoom.x -= ZOOM_SENS
				zoom.y -= ZOOM_SENS
	elif is_panning and event is InputEventMouseMotion:
		position.x -= event.relative.x * zoom.x
		position.y -= event.relative.y * zoom.x
