extends Node
class_name Server

var logger : Logger
var peer : StreamPeerTLS
var tls_options : TLSOptions
var crypto_key : CryptoKey
var certificate : X509Certificate

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
		
	#peer = StreamPeerTLS.new()
	#tls_options = TLSOptions.server(crypto_key, certificate)
	
	#var stream : StreamPeer
	#var error = peer.accept_stream(stream, tls_options)
	return true
