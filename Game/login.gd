extends Node
class_name LoginScript

const CLIENT_KEY_PATH = "user://OpenSwordsClient.key"
const CLIENT_ID_PATH = "user://OpenSwordsClient.id"
var clientKey : CryptoKey
var clientId : String
var login_server_host : String = "127.0.0.1"
var login_server_port : int = 28563
var peer_to_login_server : StreamPeerTCP
enum NextLoginState
{
	LOAD_OR_CREATE_KEY_PAIRS,
	TRY_LOAD_CLIENT_ID,
	REGISTRATION_CONNECT,
	REGISTRATION_WAIT_FOR_CONNECTION,
	REGISTRATION_SEND_REGISTRATION_REQUEST,
	LOGINQUEUE_CONNECT,
	LoginQueue_Connecting,
	LoginQueue_Connected,
	LoginQueue_WaitingInQueue,
	LOGGED_IN,
	ERROR_KEYPAIRS_NOT_AVAILABLE,
	ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER
}
var login_state : NextLoginState = NextLoginState.LOAD_OR_CREATE_KEY_PAIRS

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

func get_is_logged_in() -> bool:
	return login_state == NextLoginState.LOGGED_IN

func try_load_client_id() -> bool:
	if FileAccess.file_exists(CLIENT_ID_PATH):
		clientId = FileAccess.open(CLIENT_ID_PATH, FileAccess.READ).get_as_text()
		return not clientId.is_empty()
	return false

func initiate_connection_to_login_server() -> bool:
	print("client id does not exist yet, registering as new client at " + login_server_host + ":" + str(login_server_port))
	peer_to_login_server = StreamPeerTCP.new()
	if peer_to_login_server.connect_to_host(login_server_host, login_server_port) != OK:
		print("unable to start connection to login server to register new client, stopping login attempt")
		return false
	return true

func check_for_login_server_connection() -> StreamPeerTCP.Status:
	peer_to_login_server.poll()
	return peer_to_login_server.get_status()


func process_login() -> void:
	#print("current login state: " + NextLoginState.keys()[login_state]) #spams too much
	match login_state:
		NextLoginState.LOAD_OR_CREATE_KEY_PAIRS:
			var key_pair_prepared = load_or_create_key_pair()
			if key_pair_prepared:
				login_state = NextLoginState.TRY_LOAD_CLIENT_ID
			else:
				push_error("error loading or creating key pair")
				login_state = NextLoginState.ERROR_KEYPAIRS_NOT_AVAILABLE
			return
		NextLoginState.ERROR_KEYPAIRS_NOT_AVAILABLE:
			return
		NextLoginState.TRY_LOAD_CLIENT_ID:
			var client_id_loaded = try_load_client_id()
			if client_id_loaded:
				login_state = NextLoginState.LOGINQUEUE_CONNECT
			else:
				login_state = NextLoginState.REGISTRATION_CONNECT
			return
		NextLoginState.REGISTRATION_CONNECT:
			if initiate_connection_to_login_server():
				login_state = NextLoginState.REGISTRATION_WAIT_FOR_CONNECTION
			else:
				login_state = NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER
			return
		NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER:
			return
		NextLoginState.REGISTRATION_WAIT_FOR_CONNECTION:
			match check_for_login_server_connection():
				StreamPeerTCP.Status.STATUS_CONNECTING:
					#todo consider a timeout value?
					login_state = NextLoginState.REGISTRATION_WAIT_FOR_CONNECTION
					return
				StreamPeerTCP.Status.STATUS_CONNECTED:
					login_state = NextLoginState.REGISTRATION_SEND_REGISTRATION_REQUEST
					return
				StreamPeerTCP.Status.STATUS_NONE, StreamPeerTCP.Status.STATUS_ERROR, _:
					login_state = NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER
					return
			return
		NextLoginState.REGISTRATION_SEND_REGISTRATION_REQUEST:
			#todo continue
			return
	pass
