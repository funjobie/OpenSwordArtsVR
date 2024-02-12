extends Node
class_name Database

#see https://github.com/2shady4u/godot-sqlite
#see https://github.com/2shady4u/godot-sqlite/blob/master/demo/database.gd

var logger : Logger

const db_name := "user://database.db"

const CURRENT_DB_VERSION : int = 1
#error codes
const NO_VERSION_IN_DB : int = -1
const INCONSISTENT_VERSION_IN_DB : int = -2


const DB_VERSION_TABLE_NAME = "db_version_table"
const DB_VERSION_TABLE_VERSION_COLUMN_NAME = "version"
const USERS_TABLE_NAME = "users_table"
const USERS_TABLE_USERID_COLUMN_NAME = "user_id"
const USERS_TABLE_PUBLIC_KEY_COLUMN_NAME = "public_key"

#this represents the built in logging of SQLite output. everything explicit goes through the Logger class instead.
const sqlite_verbosity_level : int = SQLite.VERBOSE

func _init(newLogger:Logger):
	logger = newLogger
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_tables_if_not_existing(db) -> void:	
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

func upgrade_tables(db, oldVersion, newVersion) -> bool:
	logger.log_and_print(Logger.LogLevel.INFO, "upgrading db from version " + str(oldVersion) + " to version " + str(newVersion))
	logger.log_and_print(Logger.LogLevel.ERR, "upgrade from version " + str(oldVersion) + " to version " + str(newVersion) + " is not yet supported!")
	return false

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
func open_db() -> bool:
	
	logger.log_and_print(Logger.LogLevel.INFO,"starting open_db")
	var db = SQLite.new()
	db.path = db_name
	db.verbosity_level = sqlite_verbosity_level
	
	if FileAccess.file_exists(db_name):
		logger.log_and_print(Logger.LogLevel.INFO, "opening already existing database")
	else:
		logger.log_and_print(Logger.LogLevel.INFO, "creating new database")
	
		
	var success = db.open_db()
	if success:
		logger.log_and_print(Logger.LogLevel.INFO, "success opening database at " + OS.get_user_data_dir() + "/database.db")
	else:
		logger.log_and_print(Logger.LogLevel.ERR, "error opening database, please check folder " + OS.get_user_data_dir() + " allows creating files.")
	
	var localVersion : int = GetVersionFromDB(db)
	if localVersion == INCONSISTENT_VERSION_IN_DB:
		logger.log_and_print(Logger.LogLevel.ERR, "database has inconsistent versions; startup is stopped. this is not supposed to happen, consider reporting as a bug and erasing the db. ")
		return false
	elif localVersion == NO_VERSION_IN_DB:
		logger.log_and_print(Logger.LogLevel.INFO, "db does not contain version number yet -> creating table structures")
		create_tables_if_not_existing(db)
		#todo
	elif localVersion < CURRENT_DB_VERSION:
		logger.log_and_print(Logger.LogLevel.INFO, "db is outdated -> updating structure")
		if not upgrade_tables(db, localVersion, CURRENT_DB_VERSION):
			return false
		#todo
	elif localVersion > CURRENT_DB_VERSION:
		logger.log_and_print(Logger.LogLevel.ERR, "database has greater version than expected; startup is stopped. rolling back to previous software versions is currently not supported.")
		return false
	else: #same version
		logger.log_and_print(Logger.LogLevel.INFO, "db version is up to date")
	
	logger.log_and_print(Logger.LogLevel.INFO,"finished open_db")
	return true
