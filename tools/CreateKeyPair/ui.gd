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
	var internalCert = crypto.generate_self_signed_certificate(internalKey, "CN=OpenSwordArtsVR_Int,O=OpenSwordArtsVR,C=DE")
	var externalCert = crypto.generate_self_signed_certificate(externalKey, "CN=OpenSwordArtsVR_Ext,O=OpenSwordArtsVR,C=DE")

	var path = OS.get_user_data_dir()
	var dir = DirAccess.open("user://")
	print(path)
	
	# all internal server components are aware of this key thus there is no need to save the public portion of it
	var error = internalKey.save("user://OpenSwordsServerInternal.key")
	var error2 = externalKey.save("user://OpenSwordsServerExternal.key")
	var error3 = externalKey.save("user://OpenSwordsServerExternal.pub", true)
	var error4 = internalCert.save("user://OpenSwordsServerInternal.crt")
	var error5 = externalCert.save("user://OpenSwordsServerExternal.crt")
	if error != OK or error2 != OK or error3 != OK or error4 != OK or error5 != OK:
		text_edit.text = "Failure saving key and/or cert files! Please check if the following folder exists and has write access rights:\n" + path
		dir.remove("OpenSwordsServerInternal.key")
		dir.remove("OpenSwordsServerExternal.key")
		dir.remove("OpenSwordsServerExternal.pub")
		dir.remove("OpenSwordsServerInternal.crt")
		dir.remove("OpenSwordsServerExternal.crt")
	else:
		text_edit.text = "Successfully created key files in folder:\n" + path + "\nLook for \nOpenSwordsServerInternal.key\nOpenSwordsServerExternal.key\nOpenSwordsServerExternal.pub\nOpenSwordsServerInternal.crt\nOpenSwordsServerExternal.crt"

