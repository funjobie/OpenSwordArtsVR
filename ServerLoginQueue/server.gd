extends Node
class_name Server

var logger : Logger
var peers : Array[StreamPeerTLS]
var tls_options : TLSOptions
var external_crypto_key : CryptoKey
var external_certificate : X509Certificate
var server : TCPServer
# choosing a default that has a good chance of being unused: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const login_queue_port : int = 28563
const dbserver_ip : String = "127.0.0.1"
const dbserver_port : int = 34077

var process_counter : int = 0
var dropped_packet_counter : int = 0

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
	logger.log_and_print(Logger.LogLevel.INFO, "starting to open server")
	logger.log_and_print(Logger.LogLevel.INFO, "attempt to load server key from " + OS.get_user_data_dir())
	
	external_crypto_key = CryptoKey.new()
	var error = external_crypto_key.load("user://OpenSwordsServerExternal.key")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.key in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.key")
	
	external_certificate = X509Certificate.new()
	error = external_certificate.load("user://OpenSwordsServerExternal.crt")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.crt")
		
	tls_options = TLSOptions.server(external_crypto_key, external_certificate)
	server = TCPServer.new()
	server.listen(login_queue_port)
	logger.log_and_print(Logger.LogLevel.INFO, "listening for clients of the login queue on port " + str(login_queue_port))
	
	return true

func reconnect_to_db_server():
	#todo continue
	pass

func process_client_registration(packet, peer : StreamPeerTLS) -> void:
	#example public key - 813 bytes
	if typeof(packet.public_key) != TYPE_STRING or packet.public_key.length() > 2048 or packet.public_key.length() < 200:
		dropped_packet_counter = dropped_packet_counter + 1
		return
	pass
	#todo send packet to db server to actually register new client

func process_packet(packet, peer : StreamPeerTLS) -> void:
	#todo probably comment out later, might spam
	#todo input validation as otherwise malicous client can send an arbitrary long string, potentially flooding input
	if typeof(packet.packet_type) != TYPE_STRING or packet.packet_type.length() > 32:
		# no error log here - tracing the value could result in a very easy denial of service attack
		dropped_packet_counter = dropped_packet_counter + 1
		return
	logger.log_and_print(Logger.LogLevel.INFO, "received packet of type: " + packet.packet_type)
	logger.log_and_print(Logger.LogLevel.INFO, "public_key: " + packet.public_key)
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
		tls_peer.accept_stream(tcp_peer, tls_options)
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
