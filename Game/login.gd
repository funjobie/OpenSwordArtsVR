extends Node
class_name LoginScript

const CLIENT_KEY_PATH = "user://OpenSwordsClient.key"
var clientKey : CryptoKey

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func load_or_create_key_pair() -> bool:
	
	if not FileAccess.file_exists(CLIENT_KEY_PATH):
		print("client key does not yet exist, creating new one")
		var crypto = Crypto.new()
		clientKey = crypto.generate_rsa(4096)
		var error = clientKey.save(CLIENT_KEY_PATH)
		if error != OK:
			print("error saving client key, stopping login attempt")
			clientKey = null
			return false
		print("client key successfully created and saved")
		return true
	else:
		print("client key already exist, loading it")
		clientKey = CryptoKey.new()
		var error = clientKey.load(CLIENT_KEY_PATH)
		if error != OK:
			print("error loading client key, stopping login attempt")
			clientKey = null
			return false
		print("client key successfully loaded")
		return true
	pass

func login() -> bool:
	if not load_or_create_key_pair():
		return false
	#todo continue
	return true
