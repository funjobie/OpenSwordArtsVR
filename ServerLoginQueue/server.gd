extends Node
class_name Server

var logger : Logger
var peers : Array[StreamPeerTLS]
var internal_tls_options : TLSOptions
var external_tls_options : TLSOptions
var external_crypto_key : CryptoKey
var internal_certificate : X509Certificate
var external_certificate : X509Certificate
var server : TCPServer
# choosing a default that has a good chance of being unused: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const login_queue_port : int = 28563
const db_server_host : String = "127.0.0.1"
const db_server_port : int = 34077
var tcp_peer_to_db_server : StreamPeerTCP
var tls_peer_to_db_server : StreamPeerTLS

var process_counter : int = 0
var dropped_packet_counter : int = 0
var db_server_reconnect_timout_start_time : int = -1

enum NextDBServerConnectState
{
	CONNECT_TCP,
	WAIT_FOR_TCP_CONNECTION,
	CONNECT_TLS,
	WAIT_FOR_TLS_CONNECTION,
	DONE,
	ERROR_INITIATING_CONNECTION_TO_DB_SERVER
}
var db_server_connect_state : NextDBServerConnectState = NextDBServerConnectState.CONNECT_TCP

func _init(newLogger:Logger):
	logger = newLogger
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func open_server() -> bool:
	logger.log_and_print(Logger.LogLevel.INFO, "starting to open login server")
	logger.log_and_print(Logger.LogLevel.INFO, "attempt to load server keys and certificates from " + OS.get_user_data_dir())

	external_crypto_key = CryptoKey.new()
	var error = external_crypto_key.load("user://OpenSwordsServerExternal.key")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.key in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.key")
	
	internal_certificate = X509Certificate.new()
	error = internal_certificate.load("user://OpenSwordsServerInternal.crt")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerInternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerInternal.crt")

	external_certificate = X509Certificate.new()
	error = external_certificate.load("user://OpenSwordsServerExternal.crt")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.crt")
		
	internal_tls_options = TLSOptions.client(internal_certificate)
	external_tls_options = TLSOptions.server(external_crypto_key, external_certificate)
	server = TCPServer.new()
	server.listen(login_queue_port)
	logger.log_and_print(Logger.LogLevel.INFO, "listening for clients of the login queue on port " + str(login_queue_port))
	
	return true

func initiate_tcp_connection_to_db_server() -> bool:
	logger.log_and_print(Logger.LogLevel.INFO, "attempt to connect to db server at " + db_server_host + ":" + str(db_server_port))
	tcp_peer_to_db_server = StreamPeerTCP.new()
	var error = tcp_peer_to_db_server.connect_to_host(db_server_host, db_server_port)
	if error != OK:
		print("unable to start connection to login server to register new client, stopping login attempt. error: " + str(error))
		return false
	return error == OK

func check_for_tcp_db_server_connection() -> StreamPeerTCP.Status:
	tcp_peer_to_db_server.poll()
	return tcp_peer_to_db_server.get_status()
	
func initiate_tls_connection_to_db_server() -> bool:
	tls_peer_to_db_server = StreamPeerTLS.new()
	var tls_error = tls_peer_to_db_server.connect_to_stream(tcp_peer_to_db_server, "OpenSwordArtsVR_Int", internal_tls_options)
	if tls_error != OK:
		print("error initiating tls connection to login server, error code: " + str(tls_error))
	logger.log_and_print(Logger.LogLevel.INFO, "current tls status: " + str(tls_peer_to_db_server.get_status()))
	return tls_error == OK

func check_for_tls_db_server_connection() -> StreamPeerTLS.Status:
	tls_peer_to_db_server.poll()
	return tls_peer_to_db_server.get_status()

func do_state_change(new_state) -> void:
	if db_server_connect_state != new_state:
		print("[login state change]: " + NextDBServerConnectState.keys()[db_server_connect_state] + " -> " + NextDBServerConnectState.keys()[new_state])
	db_server_connect_state = new_state
	
func reconnect_to_db_server():
	match db_server_connect_state:
		NextDBServerConnectState.CONNECT_TCP:
			if initiate_tcp_connection_to_db_server():
				do_state_change(NextDBServerConnectState.WAIT_FOR_TCP_CONNECTION)
			else:
				do_state_change(NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER)
			return
		NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER:
			# reset and retry ~5s afterwards
			if db_server_reconnect_timout_start_time == -1:
				db_server_reconnect_timout_start_time = Time.get_ticks_msec()
			if Time.get_ticks_msec() - db_server_reconnect_timout_start_time > 5000:
				do_state_change(NextDBServerConnectState.CONNECT_TCP)
				db_server_reconnect_timout_start_time = -1
			return
		NextDBServerConnectState.WAIT_FOR_TCP_CONNECTION:
			match check_for_tcp_db_server_connection():
				StreamPeerTCP.Status.STATUS_CONNECTING:
					#todo consider a timeout value?
					do_state_change(NextDBServerConnectState.WAIT_FOR_TCP_CONNECTION)
					return
				StreamPeerTCP.Status.STATUS_CONNECTED:
					do_state_change(NextDBServerConnectState.CONNECT_TLS)
					return
				StreamPeerTCP.Status.STATUS_NONE, StreamPeerTCP.Status.STATUS_ERROR, _:
					do_state_change(NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER)
					return
			return
		NextDBServerConnectState.CONNECT_TLS:
			if initiate_tls_connection_to_db_server():
				do_state_change(NextDBServerConnectState.WAIT_FOR_TLS_CONNECTION)
			else:
				do_state_change(NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER)
			return
		NextDBServerConnectState.WAIT_FOR_TLS_CONNECTION:
			var tls_login_status = check_for_tls_db_server_connection()
			match tls_login_status:
				StreamPeerTLS.Status.STATUS_HANDSHAKING:
					#todo consider a timeout value?
					do_state_change(NextDBServerConnectState.WAIT_FOR_TLS_CONNECTION)
					return
				StreamPeerTLS.Status.STATUS_CONNECTED:
					#todo continue
					do_state_change(NextDBServerConnectState.DONE)
					return
				StreamPeerTLS.Status.STATUS_DISCONNECTED , StreamPeerTLS.Status.STATUS_ERROR, StreamPeerTLS.STATUS_ERROR_HOSTNAME_MISMATCH, _:
					print("tls connection failed, reason: " + str(tls_login_status))
					do_state_change(NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER)
					return
			return
		NextDBServerConnectState.DONE:
			if check_for_tls_db_server_connection() != StreamPeerTLS.Status.STATUS_CONNECTED:
				# go back to error state and reconnect
				do_state_change(NextDBServerConnectState.ERROR_INITIATING_CONNECTION_TO_DB_SERVER)
	pass

func process_client_registration(packet, peer : StreamPeerTLS) -> void:
	#example public key - 813 bytes
	if typeof(packet.public_key) != TYPE_STRING or packet.public_key.length() > 2048 or packet.public_key.length() < 200:
		dropped_packet_counter = dropped_packet_counter + 1
		return
	pass
	#todo send packet to db server to actually register new client

func process_packet(packet, peer : StreamPeerTLS) -> void:
	if typeof(packet.packet_type) != TYPE_STRING or packet.packet_type.length() > 32:
		# no error log here - tracing the value could result in a very easy denial of service attack
		dropped_packet_counter = dropped_packet_counter + 1
		return
	match packet.packet_type:
		"REGISTER_CLIENT_ID":
			process_client_registration(packet, peer)
		_:
			dropped_packet_counter = dropped_packet_counter + 1
	pass

func process() -> void:
	
	process_counter = process_counter + 1
	if process_counter % 300 == 0:
		logger.log_and_print(Logger.LogLevel.INFO, "number of dropped packets so far: " + str(dropped_packet_counter))
	
	if not server:
		# something went on on intial creation - no need to work on anything
		return
	
	reconnect_to_db_server()
	
	#todo establish connection to database server here, ensuring that login queue can handle a database server restart
	
	if server.is_connection_available():
		logger.log_and_print(Logger.LogLevel.INFO, "new connection available")
		var tcp_peer : StreamPeerTCP = server.take_connection()
		logger.log_and_print(Logger.LogLevel.INFO, "new tcp connection status: " + str(tcp_peer.get_status()))
		#todo maybe this is too early and must also await tcp being ready?
		var tls_peer : StreamPeerTLS = StreamPeerTLS.new()
		tls_peer.accept_stream(tcp_peer, external_tls_options)
		logger.log_and_print(Logger.LogLevel.INFO, "new tls connection status: " + str(tls_peer.get_status()))
		peers.append(tls_peer)
	
	var peers_to_remove : Array[StreamPeerTLS]
	for peer in peers:
		match peer.get_status():
			StreamPeerTLS.Status.STATUS_DISCONNECTED:
				logger.log_and_print(Logger.LogLevel.INFO, "connection disconnected")
				peers_to_remove.append(peer)
			StreamPeerTLS.Status.STATUS_HANDSHAKING:
				logger.log_and_print(Logger.LogLevel.INFO, "connection still at handshaking")
				peers_to_remove.append(peer)
			StreamPeerTLS.Status.STATUS_CONNECTED:
				#log probably to be commented out to avoid spam
				#logger.log_and_print(Logger.LogLevel.INFO, "connection still connected")
				peer.poll()
				if peer.get_available_bytes() > 0:
					var packet = peer.get_var()
					if packet:
						process_packet(packet, peer)
				#todo process changes
			StreamPeerTLS.Status.STATUS_ERROR:
				logger.log_and_print(Logger.LogLevel.INFO, "connection encountered an unspecified error")
				peers_to_remove.append(peer)
			StreamPeerTLS.Status.STATUS_ERROR_HOSTNAME_MISMATCH:
				logger.log_and_print(Logger.LogLevel.INFO, "connection encountered a hostname mismatch")
				peers_to_remove.append(peer)
	
	for peer in peers_to_remove:
		peers.erase(peer)
	#log commented out to avoid spam
	#logger.log_and_print(Logger.LogLevel.INFO, "number of open connections: " + str(peers.size()))
	
	pass
