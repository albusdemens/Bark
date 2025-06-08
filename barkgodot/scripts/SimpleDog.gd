extends CharacterBody3D
class_name SimpleDog

@export var move_speed: float = 5.0
@export var rotation_speed: float = 5.0

var target_position: Vector3
var is_moving: bool = false
var mesh_instance: MeshInstance3D

func _ready():
	add_to_group("dog")
	setup_dog_visual()
	
	# Set initial position
	position = Vector3(0, 1, 0)
	target_position = position

func setup_dog_visual():
	# Create simple dog representation
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Use a capsule to represent the dog
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 0.8
	mesh_instance.mesh = capsule
	
	# Brown color for dog
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.1)  # Brown
	mesh_instance.material_override = material
	
	# Add collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 0.8
	collision.shape = shape
	add_child(collision)

func _physics_process(delta):
	if is_moving:
		move_toward_target(delta)
	else:
		# Apply gravity
		if not is_on_floor():
			velocity.y += get_gravity().y * delta
			move_and_slide()

func move_toward_target(delta):
	var direction = (target_position - global_position)
	var distance = direction.length()
	
	# Check if we reached the target
	if distance < 0.5:
		is_moving = false
		velocity = Vector3.ZERO
		print("Dog reached target!")
		return
	
	# Move toward target
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Rotate to face movement direction
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()

# Voice command methods
func move_to_position(pos: Vector3):
	target_position = pos
	target_position.y = 1.0  # Keep dog at ground level
	is_moving = true
	print("Dog moving to: ", target_position)

func come_here(player_pos: Vector3):
	# Move closer to player
	var offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	move_to_position(player_pos + offset)

func sit():
	is_moving = false
	velocity = Vector3.ZERO
	print("Dog is sitting")

func stay():
	is_moving = false
	velocity = Vector3.ZERO
	print("Dog is staying")

# Test input (click to move)
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Cast ray from camera to ground
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 100
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			move_to_position(result.position)
			print("Click to move: ", result.position)
