extends Node
class_name LoginScript

const CLIENT_KEY_PATH = "user://OpenSwordsClient.key"
const CLIENT_ID_PATH = "user://OpenSwordsClient.id"
var tls_options : TLSOptions
var clientKey : CryptoKey
var clientId : String
var login_server_host : String = "127.0.0.1"
var login_server_port : int = 28563
var tcp_peer_to_login_server : StreamPeerTCP
var tls_peer_to_login_server : StreamPeerTLS
enum NextLoginState
{
	LOAD_LOGIN_SERVER_CERTIFICATE,
	LOAD_OR_CREATE_KEY_PAIRS,
	TRY_LOAD_CLIENT_ID,
	REGISTRATION_CONNECT_TCP,
	REGISTRATION_WAIT_FOR_TCP_CONNECTION,
	REGISTRATION_CONNECT_TLS,
	REGISTRATION_WAIT_FOR_TLS_CONNECTION,
	REGISTRATION_SEND_REGISTRATION_REQUEST,
	LOGINQUEUE_CONNECT,
	LoginQueue_Connecting,
	LoginQueue_Connected,
	LoginQueue_WaitingInQueue,
	LOGGED_IN,
	ERROR_SERVER_CERTIFICATE_NOT_AVAILABLE,
	ERROR_KEYPAIRS_NOT_AVAILABLE,
	ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER
}
var login_state : NextLoginState = NextLoginState.LOAD_LOGIN_SERVER_CERTIFICATE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func do_state_change(new_state) -> void:
	if login_state != new_state:
		print("[login state change]: " + NextLoginState.keys()[login_state] + " -> " + NextLoginState.keys()[new_state])
	login_state = new_state

func load_login_server_certificate() -> bool:
	var certificate : X509Certificate = X509Certificate.new()
		#todo this doesn't make sense. certificate is not supposed to be in user dir on a clean install. res dir would work, but then need to find out how to do that without having it in the source tree.
	var error = certificate.load("user://OpenSwordsServerExternal.crt")
	if error != OK:
		print("could not load OpenSwordsServerExternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	print("successfully loaded OpenSwordsServerExternal.crt")
		
	tls_options = TLSOptions.client(certificate)
	return true
	
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

func initiate_tcp_connection_to_login_server() -> bool:
	print("client id does not exist yet, registering as new client at " + login_server_host + ":" + str(login_server_port))
	tcp_peer_to_login_server = StreamPeerTCP.new()
	var error = tcp_peer_to_login_server.connect_to_host(login_server_host, login_server_port)
	if error != OK:
		print("unable to start connection to login server to register new client, stopping login attempt. error: " + str(error))
		return false
	return error == OK

func check_for_tcp_login_server_connection() -> StreamPeerTCP.Status:
	tcp_peer_to_login_server.poll()
	return tcp_peer_to_login_server.get_status()
	
func initiate_tls_connection_to_login_server() -> bool:
	tls_peer_to_login_server = StreamPeerTLS.new()
	var tls_error = tls_peer_to_login_server.connect_to_stream(tcp_peer_to_login_server, "OpenSwordArtsVR_Ext", tls_options)
	if tls_error != OK:
		print("error initiating tls connection to login server, error code: " + str(tls_error))
	print("current tls status: " + str(tls_peer_to_login_server.get_status()))
	return tls_error == OK


func check_for_tls_login_server_connection() -> StreamPeerTLS.Status:
	tls_peer_to_login_server.poll()
	return tls_peer_to_login_server.get_status()

func process_login() -> void:
	#print("current login state: " + NextLoginState.keys()[login_state]) #spams too much
	match login_state:
		NextLoginState.LOAD_LOGIN_SERVER_CERTIFICATE:
			var server_certificate_loaded = load_login_server_certificate()
			if server_certificate_loaded:
				do_state_change(NextLoginState.LOAD_OR_CREATE_KEY_PAIRS)
			else:
				do_state_change(NextLoginState.ERROR_SERVER_CERTIFICATE_NOT_AVAILABLE)
			pass
		NextLoginState.LOAD_OR_CREATE_KEY_PAIRS:
			var key_pair_prepared = load_or_create_key_pair()
			if key_pair_prepared:
				do_state_change(NextLoginState.TRY_LOAD_CLIENT_ID)
			else:
				do_state_change(NextLoginState.ERROR_KEYPAIRS_NOT_AVAILABLE)
			return
		NextLoginState.ERROR_KEYPAIRS_NOT_AVAILABLE:
			return
		NextLoginState.TRY_LOAD_CLIENT_ID:
			var client_id_loaded = try_load_client_id()
			if client_id_loaded:
				do_state_change(NextLoginState.LOGINQUEUE_CONNECT)
			else:
				do_state_change(NextLoginState.REGISTRATION_CONNECT_TCP)
			return
		NextLoginState.REGISTRATION_CONNECT_TCP:
			if initiate_tcp_connection_to_login_server():
				do_state_change(NextLoginState.REGISTRATION_WAIT_FOR_TCP_CONNECTION)
			else:
				do_state_change(NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER)
			return
		NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER:
			return
		NextLoginState.REGISTRATION_WAIT_FOR_TCP_CONNECTION:
			match check_for_tcp_login_server_connection():
				StreamPeerTCP.Status.STATUS_CONNECTING:
					#todo consider a timeout value?
					do_state_change(NextLoginState.REGISTRATION_WAIT_FOR_TCP_CONNECTION)
					return
				StreamPeerTCP.Status.STATUS_CONNECTED:
					do_state_change(NextLoginState.REGISTRATION_CONNECT_TLS)
					return
				StreamPeerTCP.Status.STATUS_NONE, StreamPeerTCP.Status.STATUS_ERROR, _:
					do_state_change(NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER)
					return
			return
		NextLoginState.REGISTRATION_CONNECT_TLS:
			if initiate_tls_connection_to_login_server():
				do_state_change(NextLoginState.REGISTRATION_WAIT_FOR_TLS_CONNECTION)
			else:
				do_state_change(NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER)
			return
		NextLoginState.REGISTRATION_WAIT_FOR_TLS_CONNECTION:
			var tls_login_status = check_for_tls_login_server_connection()
			match tls_login_status:
				StreamPeerTLS.Status.STATUS_HANDSHAKING:
					#todo consider a timeout value?
					do_state_change(NextLoginState.REGISTRATION_WAIT_FOR_TLS_CONNECTION)
					return
				StreamPeerTLS.Status.STATUS_CONNECTED:
					do_state_change(NextLoginState.REGISTRATION_SEND_REGISTRATION_REQUEST)
					return
				StreamPeerTLS.Status.STATUS_DISCONNECTED , StreamPeerTLS.Status.STATUS_ERROR, StreamPeerTLS.STATUS_ERROR_HOSTNAME_MISMATCH, _:
					print("tls connection failed, reason: " + str(tls_login_status))
					do_state_change(NextLoginState.ERROR_INITIATING_CONNECTION_TO_LOGIN_SERVER)
					return
			return
		NextLoginState.REGISTRATION_SEND_REGISTRATION_REQUEST:
			#todo continue
			return
	pass
