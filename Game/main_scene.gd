extends Node3D

var login_script := preload("res://login.gd")
var login_handler : LoginScript

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_handler = login_script.new()		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not login_handler.get_is_logged_in():
		login_handler.process_login()
	pass
