extends Node3D

func _ready():
	setup_ground()
	setup_camera()
	setup_lighting()
	setup_ui()

func setup_ground():
	# Create ground plane
	var ground_body = StaticBody3D.new()
	add_child(ground_body)
	
	# Ground mesh
	var mesh_instance = MeshInstance3D.new()
	ground_body.add_child(mesh_instance)
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(50, 50)  # 50x50 meter ground
	mesh_instance.mesh = plane_mesh
	
	# Ground material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2)  # Green ground
	mesh_instance.material_override = material
	
	# Ground collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(50, 0.1, 50)
	collision.shape = box_shape
	collision.position.y = -0.05
	ground_body.add_child(collision)

func setup_camera():
	# Create camera
	var camera = Camera3D.new()
	add_child(camera)
	
	# Position camera to look down at the scene
	camera.position = Vector3(10, 8, 10)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func setup_lighting():
	# Add directional light (sun)
	var light = DirectionalLight3D.new()
	add_child(light)
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, -45, 0)
	light.light_energy = 1.0

func setup_ui():
	# Create UI for voice feedback
	var ui = Control.new()
	add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Voice status label
	var label = Label.new()
	ui.add_child(label)
	label.text = "Press SPACE for voice command\nPress T to test 'come here'\nClick to move dog"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 16)
