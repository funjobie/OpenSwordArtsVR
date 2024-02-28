extends Node
class_name Server

var logger : Logger
var peers : Array[StreamPeerTLS]
var tls_options : TLSOptions
var crypto_key : CryptoKey
var certificate : X509Certificate
var server : TCPServer
# choosing a default that has a good chance of being unused: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const port : int = 34077

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
	
	crypto_key = CryptoKey.new()
	var error = crypto_key.load("user://OpenSwordsServerInternal.key")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerInternal.key in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerInternal.key")
	
	certificate = X509Certificate.new()
	error = certificate.load("user://OpenSwordsServerInternal.crt")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerInternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerInternal.crt")
		
	tls_options = TLSOptions.server(crypto_key, certificate)
	server = TCPServer.new()
	server.listen(port)
	logger.log_and_print(Logger.LogLevel.INFO, "listening for clients of the database server on port " + str(port))
	
	return true

func process() -> void:
	
	if not server:
		return
	
	if server.is_connection_available():
		logger.log_and_print(Logger.LogLevel.INFO, "new connection available")
		var tcp_peer : StreamPeerTCP = server.take_connection()
		var tls_peer : StreamPeerTLS = StreamPeerTLS.new()
		tls_peer.accept_stream(tcp_peer, tls_options)
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
				#todo process changes
			StreamPeerTLS.Status.STATUS_ERROR:
				logger.log_and_print(Logger.LogLevel.INFO, "connection encountered an unspecified error")
				peers_to_remove.append(peer)
			StreamPeerTLS.Status.STATUS_ERROR_HOSTNAME_MISMATCH:
				logger.log_and_print(Logger.LogLevel.INFO, "connection encountered a hostname mismatch")
				peers_to_remove.append(peer)
	
	for peer in peers_to_remove:
		peers.erase(peer)

	process_counter = process_counter + 1
	if process_counter % 300 == 0:
		logger.log_and_print(Logger.LogLevel.INFO, "number of open connections: " + str(peers.size()))
		logger.log_and_print(Logger.LogLevel.INFO, "number of dropped packets so far: " + str(dropped_packet_counter))
	
	pass
