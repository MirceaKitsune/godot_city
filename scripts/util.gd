class_name Util

static func get_json(f: String):
	var json = JSON.new()
	if FileAccess.file_exists(f):
		var file = FileAccess.open(f, FileAccess.READ)
		json.parse(file.get_as_text())
	return json.get_data()
