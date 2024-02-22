extends Node
class_name Server

var logger : Logger
var peers : Array[StreamPeerTLS]
var tls_options : TLSOptions
var crypto_key : CryptoKey
var certificate : X509Certificate
var server : TCPServer
# choosing a default that has a good chance of being unused: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const login_queue_port : int = 28563
const dbserver_queue_port : int = 34077

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
	var error = crypto_key.load("user://OpenSwordsServerExternal.key")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.key in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.key")
	
	certificate = X509Certificate.new()
	error = certificate.load("user://OpenSwordsServerExternal.crt")
	if error != OK:
		logger.log_and_print(Logger.LogLevel.ERR, "could not load OpenSwordsServerExternal.crt in user dir, please create it and place it there. server startup is stopped. error code: " + str(error))
		return false
	logger.log_and_print(Logger.LogLevel.INFO, "successfully loaded OpenSwordsServerExternal.crt")
		
	tls_options = TLSOptions.server(crypto_key, certificate)
	server = TCPServer.new()
	server.listen(login_queue_port)
	logger.log_and_print(Logger.LogLevel.INFO, "listening for clients of the login queue on port " + str(login_queue_port))
	
	return true

func process() -> void:
	
	if not server:
		return
		
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
				logger.log_and_print(Logger.LogLevel.INFO, "connection still connected")
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
	#log commented out to avoid spam
	#logger.log_and_print(Logger.LogLevel.INFO, "number of open connections: " + str(peers.size()))
	
	pass
