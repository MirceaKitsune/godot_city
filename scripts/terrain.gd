extends Node3D

@export var seed = 0
@export var size = 4
@export var height = 0.25
@export var mat = "rocks"

func _generate_mesh(pos: Vector3, noise: OpenSimplexNoise):
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
			st.add_triangle_fan(PackedVector3Array([corner_1, corner_2, corner_3]), PackedVector2Array([uv_1, uv_2, uv_3]))
			st.add_triangle_fan(PackedVector3Array([corner_4, corner_3, corner_2]), PackedVector2Array([uv_4, uv_3, uv_2]))

	st.index()
	st.generate_normals()
	st.set_material(load("res://data/materials/" + mat + ".tres"))
	return st.commit()

func _generate():
	# Terrain patches must have the same rotation, extract rotation offset from the parent node
	var pos = get_parent().position
	var rot = get_parent().rotation
	rotation -= rot

	var n = OpenSimplexNoise.new()
	n.seed = seed
	n.octaves = 0
	n.lacunarity = 0
	n.period = size
	n.persistence = 0.5

	var m = MeshInstance3D.new()
	m.mesh = _generate_mesh(pos, n)
	m.create_trimesh_collision()
	add_child(m)

func _ready():
	call_deferred("_generate")
