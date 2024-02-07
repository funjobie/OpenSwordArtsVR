extends Node

var database_script := preload("res://database.gd")

@onready var logger: RichTextLabel = $LoggerRichTextLabel
var database : Database

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger.log_and_print(Logger.LogLevel.INFO, "Logger initialized")
	database = database_script.new(logger)
	database.open_db()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
