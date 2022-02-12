class_name Util

static func get_json(f: String):
	var file = File.new()
	var json = JSON.new()
	file.open(f, File.READ)
	json.parse(file.get_as_text())
	return json.get_data()
