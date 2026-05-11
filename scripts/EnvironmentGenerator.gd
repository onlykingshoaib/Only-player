## EnvironmentGenerator.gd
## Zero-lag environment generation using MultiMesh instances
## Efficiently populates the game map with buildings, trees, and props

extends Node3D

# Configuration
@export var map_size: float = 500.0
@export var building_count: int = 20
@export var tree_count: int = 100
@export var prop_count: int = 50

# Asset paths (replace with actual models)
@export var building_model_path: String = "res://assets/models/building.obj"
@export var tree_model_path: String = "res://assets/models/tree.obj"
@export var prop_model_path: String = "res://assets/models/prop.obj"

# References
var building_multimesh: MultiMeshInstance3D
var tree_multimesh: MultiMeshInstance3D
var prop_multimesh: MultiMeshInstance3D

# Random seed for reproducible map generation
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = hash(get_tree().current_scene.name)
	
	# Create multimesh containers
	_create_buildings()
	_create_trees()
	_create_props()

func _create_buildings() -> void:
	building_multimesh = MultiMeshInstance3D.new()
	add_child(building_multimesh)
	building_multimesh.name = "Buildings"
	
	# Try to load model, fallback to simple mesh
	var mesh = _load_or_create_mesh(building_model_path, "building")
	if mesh:
		var multimesh = MultiMesh.new()
		multimesh.mesh = mesh
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = building_count
		
		# Populate instances
		for i in range(building_count):
			var transform = Transform3D()
			transform.origin = _random_position_on_map()
			transform.basis = Basis()  # Identity rotation
			multimesh.set_instance_transform(i, transform)
		
		building_multimesh.multimesh = multimesh
		
		# Apply material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GRAY
		material.normal_scale = 1.0
		building_multimesh.set_surface_override_material(0, material)

func _create_trees() -> void:
	tree_multimesh = MultiMeshInstance3D.new()
	add_child(tree_multimesh)
	tree_multimesh.name = "Trees"
	
	var mesh = _load_or_create_mesh(tree_model_path, "tree")
	if mesh:
		var multimesh = MultiMesh.new()
		multimesh.mesh = mesh
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = tree_count
		
		for i in range(tree_count):
			var transform = Transform3D()
			transform.origin = _random_position_on_map()
			transform.origin.y = 5.0  # Raise trees above ground
			multimesh.set_instance_transform(i, transform)
		
		tree_multimesh.multimesh = multimesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		tree_multimesh.set_surface_override_material(0, material)

func _create_props() -> void:
	prop_multimesh = MultiMeshInstance3D.new()
	add_child(prop_multimesh)
	prop_multimesh.name = "Props"
	
	var mesh = _load_or_create_mesh(prop_model_path, "prop")
	if mesh:
		var multimesh = MultiMesh.new()
		multimesh.mesh = mesh
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = prop_count
		
		for i in range(prop_count):
			var transform = Transform3D()
			transform.origin = _random_position_on_map()
			multimesh.set_instance_transform(i, transform)
		
		prop_multimesh.multimesh = multimesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.7)
		prop_multimesh.set_surface_override_material(0, material)

func _load_or_create_mesh(path: String, fallback_type: String) -> Mesh:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Mesh:
			return resource
	
	# Fallback mesh creation
	match fallback_type:
		"building":
			var box = BoxMesh.new()
			box.size = Vector3(4, 8, 4)
			return box
		"tree":
			var cyl = CylinderMesh.new()
			cyl.radius = 2.0
			cyl.height = 12.0
			return cyl
		"prop":
			var sphere = SphereMesh.new()
			sphere.radius = 1.0
			return sphere
	
	return null

func _random_position_on_map() -> Vector3:
	var x = rng.randf_range(-map_size / 2, map_size / 2)
	var z = rng.randf_range(-map_size / 2, map_size / 2)
	return Vector3(x, 0, z)

## Update environment at runtime (for dynamic destruction/spawning)
func update_instance(type: String, index: int, transform: Transform3D) -> void:
	var multimesh_instance = null
	
	match type:
		"building":
			multimesh_instance = building_multimesh
		"tree":
			multimesh_instance = tree_multimesh
		"prop":
			multimesh_instance = prop_multimesh
	
	if multimesh_instance and multimesh_instance.multimesh:
		multimesh_instance.multimesh.set_instance_transform(index, transform)
