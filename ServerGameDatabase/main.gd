extends Node

var database_script := preload("res://database.gd")
var server_script := preload("res://server.gd")

@onready var logger: RichTextLabel = $LoggerRichTextLabel
var database : Database
var server : Server

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger.log_and_print(Logger.LogLevel.INFO, "Logger initialized")
	database = database_script.new(logger)
	var open_success = database.open_db()
	if not open_success:
		logger.log_and_print(Logger.LogLevel.ERR, "an error occured previously, will not open server")
		return
	server = server_script.new(logger)
	if not server.open_server():
		logger.log_and_print(Logger.LogLevel.ERR, "an error occured opening the server")
		return
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
