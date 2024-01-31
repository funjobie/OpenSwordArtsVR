extends Control

#see https://github.com/2shady4u/godot-sqlite
#see https://github.com/2shady4u/godot-sqlite/blob/master/demo/database.gd


#@onready var text_edit: TextEdit = $TextEdit
#@onready var rich_text_label: RichTextLabel = $RichTextLabel
@onready var text_edit: RichTextLabel = $RichTextLabel

const db_name := "user://database.db"
#long term, instead use explicit logging instead, but this can be used when fine tuning queries
const verbosity_level : int = SQLite.VERBOSE
const visible_log_length : int = 100*1000
enum LogLevel
{
	INFO, WARN, ERR
}

func log_and_print(severity : LogLevel, text) -> void:
	#todo consider also creating a log file?
	print(text)
	var strToAdd
	if severity == LogLevel.INFO:
		strToAdd = "[color=white]" + text + "[/color]"
	if severity == LogLevel.WARN:
		strToAdd = "[color=yellow]" + text + "[/color]"
	if severity == LogLevel.ERR:
		strToAdd = "[color=red]" + text + "[/color]"
	text_edit.text += strToAdd + "\n"
	if text_edit.text.length() > visible_log_length:
		text_edit.text = text_edit.text.right(visible_log_length / 2)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var db = SQLite.new()
	db.path = db_name
	db.verbosity_level = verbosity_level

	log_and_print(LogLevel.INFO, "sample info log")
	log_and_print(LogLevel.WARN, "sample warning log")
	log_and_print(LogLevel.ERR, "sample error log")
	
	if FileAccess.file_exists(db_name):
		log_and_print(LogLevel.INFO, "opening already existing database")
	else:
		log_and_print(LogLevel.INFO, "creating new database")
	
		
	var success = db.open_db()
	if success:
		log_and_print(LogLevel.INFO, "success opening database at " + OS.get_user_data_dir() + "/database.db")
	else:
		log_and_print(LogLevel.ERR, "error opening database, please check folder " + OS.get_user_data_dir() + " allows creating files.")
		
		
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
