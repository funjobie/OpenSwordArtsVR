extends Control

var server_script := preload("res://server.gd")
@onready var logger: RichTextLabel = $LoggerRichTextLabel

var server : Server

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger.log_and_print(Logger.LogLevel.INFO, "Logger initialized")
	server = server_script.new(logger)
	if not server.open_server():
		logger.log_and_print(Logger.LogLevel.ERR, "an error occured opening the server")
		return
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	server.process()
	pass
