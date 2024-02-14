extends Node3D

var login_script := preload("res://login.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var login : LoginScript = login_script.new()
	var logged_in = login.login()
	if not logged_in:
		push_error("error logging in")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
