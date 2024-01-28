extends Control

@onready var text_edit: TextEdit = $TextEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_create_key_pair_button_pressed() -> void:
	
	var crypto = Crypto.new()
	var internalKey = crypto.generate_rsa(4096)
	var externalKey = crypto.generate_rsa(4096)

	var path = OS.get_user_data_dir()
	var dir = DirAccess.open("user://")
	print(path)
	
	# all internal server components are aware of this key thus there is no need to save the public portion of it
	var error = internalKey.save("user://OpenSwordsServerInternal.key")
	var error2 = externalKey.save("user://OpenSwordsServerExternal.key")
	var error3 = externalKey.save("user://OpenSwordsServerExternal.pub", true)
	if error != OK or error2 != OK or error3 != OK:
		text_edit.text = "Failure saving key files! Please check if the following folder exists and has write access rights:\n" + path
		dir.remove("OpenSwordsServerInternal.key")
		dir.remove("OpenSwordsServerExternal.key")
		dir.remove("OpenSwordsServerExternal.pub")
	else:
		text_edit.text = "Successfully created key files in folder:\n" + path + "\nLook for \nOpenSwordsServerInternal.key\nOpenSwordsServerExternal.key\nOpenSwordsServerExternal.pub"

