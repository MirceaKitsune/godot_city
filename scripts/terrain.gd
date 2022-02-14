extends Node3D

@export var seed = 0
@export var size = 4
@export var height = 0.25
@export var mat = "rocks"

func _mesh(pos: Vector3):
	var noise = OpenSimplexNoise.new()
	noise.seed = seed
	noise.octaves = 0
	noise.lacunarity = 0
	noise.period = size
	noise.persistence = 0.5

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var s = floor(size / 2)
	for x in range(-s, s, 1):
		for z in range(-s, s, 1):
			var uv_1 = Vector2(x, z)
			var uv_2 = Vector2(x + 1, z)
			var uv_3 = Vector2(x, z + 1)
			var uv_4 = Vector2(x + 1, z + 1)
			var corner_1 = Vector3(uv_1.x, noise.get_noise_2d(uv_1.x + pos.x, uv_1.y + pos.z) * height, uv_1.y)
			var corner_2 = Vector3(uv_2.x, noise.get_noise_2d(uv_2.x + pos.x, uv_2.y + pos.z) * height, uv_2.y)
			var corner_3 = Vector3(uv_3.x, noise.get_noise_2d(uv_3.x + pos.x, uv_3.y + pos.z) * height, uv_3.y)
			var corner_4 = Vector3(uv_4.x, noise.get_noise_2d(uv_4.x + pos.x, uv_4.y + pos.z) * height, uv_4.y)

			# First triangle
			st.set_uv(uv_1)
			st.add_vertex(corner_1)
			st.set_uv(uv_2)
			st.add_vertex(corner_2)
			st.set_uv(uv_3)
			st.add_vertex(corner_3)

			# Second triangle
			st.set_uv(uv_4)
			st.add_vertex(corner_4)
			st.set_uv(uv_3)
			st.add_vertex(corner_3)
			st.set_uv(uv_2)
			st.add_vertex(corner_2)

	st.index()
	st.generate_normals()
	st.set_material(load("res://data/materials/" + mat + ".tres"))
	return st.commit()

func _ready():
	var m = MeshInstance3D.new()
	var pos = get_parent().position
	m.mesh = _mesh(pos)
	m.create_trimesh_collision()
	add_child(m)

	# All instances must have the same rotation
	get_parent().rotation = Vector3(0, 0, 0)
