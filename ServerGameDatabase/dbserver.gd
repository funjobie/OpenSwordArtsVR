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
const CURRENT_DB_VERSION : int = 1

const DB_VERSION_TABLE_NAME = "db_version_table"
const DB_VERSION_TABLE_VERSION_COLUMN_NAME = "version"
const USERS_TABLE_NAME = "users_table"
const USERS_TABLE_USERID_COLUMN_NAME = "user_id"
const USERS_TABLE_PUBLIC_KEY_COLUMN_NAME = "public_key"

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

func create_tables_if_not_existing(db) -> void:
	#var table_dict : Dictionary = Dictionary()
	#table_dict["id"] = {"data_type":"int", "primary_key": true, "not_null": true}
	#table_dict["name"] = {"data_type":"text", "not_null": true}
	#table_dict["age"] = {"data_type":"int", "not_null": true}
	#table_dict["address"] = {"data_type":"char(50)"}
	#table_dict["salary"] = {"data_type":"real"}
	
	var db_version_table_dict : Dictionary = Dictionary()
	db_version_table_dict[DB_VERSION_TABLE_VERSION_COLUMN_NAME] = {"data_type":"int", "primary_key": true, "not_null": true}
	db.create_table(DB_VERSION_TABLE_NAME, db_version_table_dict)
	var db_version_table_row_dict : Dictionary = Dictionary()
	db_version_table_row_dict[DB_VERSION_TABLE_VERSION_COLUMN_NAME] = CURRENT_DB_VERSION
	db.insert_row(DB_VERSION_TABLE_NAME, db_version_table_row_dict)
	
	var users_table_dict : Dictionary = Dictionary()
	users_table_dict[USERS_TABLE_USERID_COLUMN_NAME] = {"data_type":"text", "primary_key": true, "not_null": true}
	users_table_dict[USERS_TABLE_PUBLIC_KEY_COLUMN_NAME] = {"data_type":"text", "not_null": true}
	db.create_table(USERS_TABLE_NAME, users_table_dict)
	
	pass

func upgrade_tables(db, oldVersion, newVersion) -> void:
	log_and_print(LogLevel.INFO, "upgrading db from version " + str(oldVersion) + " to version " + str(newVersion))
	log_and_print(LogLevel.ERR, "upgrade from version " + str(oldVersion) + " to version " + str(newVersion) + " is not yet supported!")
	pass

const NO_VERSION_IN_DB : int = -1
const INCONSISTENT_VERSION_IN_DB : int = -2

func GetVersionFromDB(db) -> int:
	
	var select_condition : String = ""
	var selected_array : Array = db.select_rows(DB_VERSION_TABLE_NAME, select_condition, [DB_VERSION_TABLE_VERSION_COLUMN_NAME])
	
	print("condition: " + select_condition)
	print("result: {0}".format([str(selected_array)]))
	
	if selected_array.size() == 0:
		return NO_VERSION_IN_DB
	elif selected_array.size() > 1:
		return INCONSISTENT_VERSION_IN_DB
	return selected_array[0][DB_VERSION_TABLE_VERSION_COLUMN_NAME]

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
	
	var localVersion : int = GetVersionFromDB(db)
	if localVersion == INCONSISTENT_VERSION_IN_DB:
		log_and_print(LogLevel.ERR, "database has inconsistent versions; startup is stopped. this is not supposed to happen, consider reporting as a bug and erasing the db. ")
		return
	elif localVersion == NO_VERSION_IN_DB:
		log_and_print(LogLevel.INFO, "db does not contain version number yet -> creating table structures")
		create_tables_if_not_existing(db)
		#todo
	elif localVersion < CURRENT_DB_VERSION:
		log_and_print(LogLevel.INFO, "db is outdated -> updating structure")
		upgrade_tables(db, localVersion, CURRENT_DB_VERSION)
		#todo
	elif localVersion > CURRENT_DB_VERSION:
		log_and_print(LogLevel.ERR, "database has greater version than expected; startup is stopped. rolling back to previous software versions is currently not supported.")
		return
	else: #same version
		log_and_print(LogLevel.INFO, "db version is up to date")
	

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
