extends RichTextLabel
class_name Logger

const visible_log_length : int = 100*1000
enum LogLevel
{
	INFO, WARN, ERR
}

func log_and_print(severity : LogLevel, newText) -> void:
	#todo consider also creating a log file?
	print(newText)
	var strToAdd
	if severity == LogLevel.INFO:
		strToAdd = "[color=white]" + newText + "[/color]"
	if severity == LogLevel.WARN:
		strToAdd = "[color=yellow]" + newText + "[/color]"
	if severity == LogLevel.ERR:
		strToAdd = "[color=red]" + newText + "[/color]"
	text += strToAdd + "\n"
	if text.length() > visible_log_length:
		text = text.right(visible_log_length / 2)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	log_and_print(Logger.LogLevel.INFO, "sample info log")
	log_and_print(Logger.LogLevel.WARN, "sample warning log")
	log_and_print(Logger.LogLevel.ERR, "sample error log")

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
