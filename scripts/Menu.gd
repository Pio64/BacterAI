extends Control


# Declare member variables here. Examples:
export (PackedScene) var game_scene
onready var main_screen = $Overlay/Buttons/Grid
onready var load_menu = $Overlay/Buttons/LoadMenu
onready var saved_network_list = $Overlay/Buttons/LoadMenu/ItemList
var standalone_network

# Called when the node enters the scene tree for the first time.
func _ready():
	standalone_network = load("res://NEAT_usability/standalone_scripts/standalone_neuralnet.gd").new()


func _on_ExitBtn_button_down():
	get_tree().quit()


func _on_StartBtn_button_down():
	start_game()


# show load menu
func _on_LoadBtn_button_down():
	saved_network_list.clear()

	main_screen.visible = false
	load_menu.visible = true

	for save in standalone_network.get_saved_networks():
		saved_network_list.add_item(save)


# exit load menu
func _on_BackBtn_button_down():
	load_menu.visible = false
	main_screen.visible = true


func _on_ItemList_item_selected(index):
	var selected_network = saved_network_list.get_item_text(index)
	Global.custom_network_name = selected_network
	start_game()


func start_game():
	get_tree().change_scene_to(game_scene)
