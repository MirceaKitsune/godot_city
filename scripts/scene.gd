extends Node3D

@export var tileset = "default"
@export var count = 64
@export var height = 0

class _tileset extends Node3D:
	# parent: The node that tile scenes will be parented to
	# def: The JSON definition of this tileset
	# scenes: Stores the scenes of all tiles defined by brushes, indexed by brush name + tile name + variation index
	# scenes_tile: Individual instances of scenes, indexed by tile position
	# tiles: The brush name of this tile, indexed by tile position
	# tiles_var: A value between 0 and 1 indicating the tile variation at this location, indexed by tile position
	var parent: Node3D
	var def: Dictionary
	var scenes: Dictionary
	var scenes_tile: Dictionary
	var tiles: Dictionary
	var tiles_var: Dictionary

	func _init(p: Node3D, n: String):
		var path = "res://data/tiles/" + n + "/"
		parent = p
		def = Util.get_json(path + "tiles.json")

		# Preload the tile scenes for each brush
		for brush in def.brushes:
			for tile in def.brushes[brush].tileset:
				for variation in def.brushes[brush].tileset[tile].size():
					var scene_name = brush + "_" + tile + "_" + str(variation)
					var scene_file = brush + "/" + def.brushes[brush].tileset[tile][variation] + ".tscn"
					scenes[scene_name] = load(path + scene_file)

	func _tile_update(pos: Vector3i):
		var scene_pos: Vector3
		var scene_rot: Vector3
		var scene_name: String
		if not tiles[pos].is_empty():
			# single: Connects 0 points, used when the tile has no valid neighbors to connect to, always used if other types aren't defined
			# center: Connects 4 points, used when the tile is surrounded on all sides
			# edge: Connects 2 points in a line, used when touching 1 neighbor laterally
			# edge_inward: Connects 3 points in a line, used when touching 1 neighbor diagonally and 2 laterally around it
			# edge_outward: Connects 1 point, used when touching 1 neighbor diagonally
			# edge_outward_diagonal: Connects 2 points diagonally, used when touching 2 neighbors diagonally on opposite sides
			var type = ["single", 0]
			if def.brushes[tiles[pos]].tileset.size() > 1:
				# The 8 neighbor positions are stored clockwise starting from the top-left corner
				# 0 = top left, 1 = top, 2 = top right, 3 = right, 4 = bottom right, 5 = bottom, 6 = bottom left, 7 = left
				var pos_neighbors = [
					Vector3i(pos.x - 1, pos.y, pos.z - 1),
					Vector3i(pos.x, pos.y, pos.z - 1),
					Vector3i(pos.x + 1, pos.y, pos.z - 1),
					Vector3i(pos.x + 1, pos.y, pos.z),
					Vector3i(pos.x + 1, pos.y, pos.z + 1),
					Vector3i(pos.x, pos.y, pos.z + 1),
					Vector3i(pos.x - 1, pos.y, pos.z + 1),
					Vector3i(pos.x - 1, pos.y, pos.z)
				]
				var has = [
					tiles.has(pos) and tiles.has(pos_neighbors[0]) and tiles[pos] == tiles[pos_neighbors[0]],
					tiles.has(pos) and tiles.has(pos_neighbors[1]) and tiles[pos] == tiles[pos_neighbors[1]],
					tiles.has(pos) and tiles.has(pos_neighbors[2]) and tiles[pos] == tiles[pos_neighbors[2]],
					tiles.has(pos) and tiles.has(pos_neighbors[3]) and tiles[pos] == tiles[pos_neighbors[3]],
					tiles.has(pos) and tiles.has(pos_neighbors[4]) and tiles[pos] == tiles[pos_neighbors[4]],
					tiles.has(pos) and tiles.has(pos_neighbors[5]) and tiles[pos] == tiles[pos_neighbors[5]],
					tiles.has(pos) and tiles.has(pos_neighbors[6]) and tiles[pos] == tiles[pos_neighbors[6]],
					tiles.has(pos) and tiles.has(pos_neighbors[7]) and tiles[pos] == tiles[pos_neighbors[7]]
				]

				# Pick the appropriate scene and rotation based on the neighbors we connect to
				if has[0] and has[1] and has[2] and has[3] and has[4] and has[5] and has[6] and has[7]:
					type = ["center", 0]
				elif has[0] and has[1] and has[2] and has[3] and has[5] and has[6] and has[7]:
					type = ["edge_inward", 1]
				elif has[0] and has[1] and has[2] and has[3] and has[4] and has[5] and has[7]:
					type = ["edge_inward", 0]
				elif has[1] and has[2] and has[3] and has[4] and has[5] and has[6] and has[7]:
					type = ["edge_inward", 3]
				elif has[0] and has[1] and has[3] and has[4] and has[5] and has[6] and has[7]:
					type = ["edge_inward", 2]
				elif has[3] and has[4] and has[5] and has[6] and has[7]:
					type = ["edge", 3]
				elif has[0] and has[1] and has[5] and has[6] and has[7]:
					type = ["edge", 2]
				elif has[0] and has[1] and has[2] and has[3] and has[7]:
					type = ["edge", 1]
				elif has[1] and has[2] and has[3] and has[4] and has[5]:
					type = ["edge", 0]
				elif has[0] and has[1] and has[3] and has[4] and has[5] and has[7]:
					type = ["edge_outward_diagonal", 1]
				elif has[1] and has[2] and has[3] and has[5] and has[6] and has[7]:
					type = ["edge_outward_diagonal", 0]
				elif has[3] and has[4] and has[5]:
					type = ["edge_outward", 3]
				elif has[5] and has[6] and has[7]:
					type = ["edge_outward", 2]
				elif has[0] and has[1] and has[7]:
					type = ["edge_outward", 1]
				elif has[1] and has[2] and has[3]:
					type = ["edge_outward", 0]

			# The noise value at this position is transposed to the total number of variations available for this tile
			# Due to how the noise pattern works, items first in the list have a higher probability of being picked
			var variations = def.brushes[tiles[pos]].tileset[type[0]].size()
			var variation = floor(tiles_var[pos] * variations)

			# Determine the real name position and rotation used by the scene node
			scene_pos = pos * def.scale
			scene_rot = Vector3(0, 1, 0) * deg2rad(type[1] * 90)
			scene_name = tiles[pos] + "_" + type[0] + "_" + str(variation)

		# Remove the existing scene before proceeding, skip if the existing scene has identical properties
		if scenes_tile.has(pos):
			if scenes_tile[pos].position == scene_pos and scenes_tile[pos].rotation == scene_rot and scenes_tile[pos].name == scene_name:
				return
			scenes_tile[pos].queue_free()
			scenes_tile.erase(pos)

		# Set a new scene if a desired name is specified
		if not tiles[pos].is_empty():
			scenes_tile[pos] = scenes[scene_name].instantiate()
			scenes_tile[pos].position = scene_pos
			scenes_tile[pos].rotation = scene_rot
			scenes_tile[pos].name = scene_name
			parent.add_child(scenes_tile[pos])

	func generate(mins: Vector3i, maxs: Vector3i, seed: int):
		# Noise used to determine tile type
		var noise = FastNoiseLite.new()
		noise.noise_type = noise.TYPE_SIMPLEX
		noise.seed = seed
		noise.frequency = def.noise_generator_scale

		# Noise used to determine tile variation
		var noise_variation = FastNoiseLite.new()
		noise_variation.noise_type = noise.TYPE_SIMPLEX
		noise_variation.seed = seed + 1
		noise_variation.frequency = def.noise_variation_scale

		# Translate noise values into the tiles table
		for x in range(mins.x, maxs.x + 1, 1):
			for y in range(mins.y, maxs.y + 1, 1):
				for z in range(mins.z, maxs.z + 1, 1):
					var pos = Vector3i(x, y, z)
					var scene_pos = pos * def.scale
					var n = abs(noise.get_noise_3dv(scene_pos))
					tiles[pos] = ""
					tiles_var[pos] = 0
					for brush in def.brushes:
						if def.brushes[brush].height == y and n >= def.brushes[brush].noise_min and n <= def.brushes[brush].noise_max:
							var nv = (1 + noise_variation.get_noise_3dv(scene_pos)) / 2
							tiles[pos] = brush
							tiles_var[pos] = nv

		# Update all tiles in the changed area
		for x in range(mins.x, maxs.x + 1, 1):
			for y in range(mins.y, maxs.y + 1, 1):
				for z in range(mins.z, maxs.z + 1, 1):
					var pos = Vector3i(x, y, z)
					_tile_update(pos)

func _ready():
	var size = floor(count / 2)
	var size_mins = Vector3i(-size, -height, -size)
	var size_maxs = Vector3i(size, height, size)
	var t = _tileset.new(self, tileset)
	t.generate(size_mins, size_maxs, randi())
