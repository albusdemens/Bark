extends Node
# AutoLoad singleton

signal command_received(text: String)

var is_listening: bool = false
var camera: Camera3D

# Test commands for simulation
var test_commands = [
	"come here",
	"sit down", 
	"stay there",
	"go over there",
	"good boy"
]

func _ready():
	print("✅ SimpleVoiceManager loaded!")  # Add this
	print("Commands: SPACE = voice, T = test command")

func _input(event):
	print("📝 Input event received: ", event)  # Add this
	if event is InputEventKey and event.pressed:
		print("🔑 Key pressed: ", event.keycode, " (SPACE=", KEY_SPACE, ", T=", KEY_T, ")")  # Add this
		if event.keycode == KEY_SPACE:
			print("🚀 SPACE detected!")  # Add this
			start_listening()
		elif event.keycode == KEY_T:
			print("🧪 T detected!")  # Add this
			test_command()

func start_listening():
	if is_listening:
		return
	
	print("🎤 Listening for voice command...")
	is_listening = true
	
	# Simulate voice recognition with timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_on_listen_timeout)
	timer.start()

func _on_listen_timeout():
	# Simulate getting a random voice command
	var command = test_commands[randi() % test_commands.size()]
	print("🗣️ Heard: '", command, "'")
	
	is_listening = false
	command_received.emit(command)
	process_command(command)

func test_command():
	var command = "come here"
	print("🧪 Test command: '", command, "'")
	command_received.emit(command)
	process_command(command)

func process_command(text: String):
	text = text.to_lower().strip_edges()
	
	# Find the dog
	var dog = get_tree().get_first_node_in_group("dog")
	if not dog:
		print("❌ No dog found in scene!")
		return
	
	# Get camera/player position
	var player_pos = get_player_position()
	
	# Parse simple commands
	if "come" in text or "here" in text:
		print("📍 Calling dog to come here")
		dog.come_here(player_pos)
	elif "sit" in text:
		print("🐕 Telling dog to sit")
		dog.sit()
	elif "stay" in text or "wait" in text:
		print("✋ Telling dog to stay")
		dog.stay()
	elif "go" in text or "there" in text:
		print("👉 Telling dog to go somewhere")
		# Move to a random nearby position
		var random_pos = player_pos + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		dog.move_to_position(random_pos)
	else:
		print("❓ Unknown command: ", text)

func get_player_position() -> Vector3:
	if not camera:
		camera = get_viewport().get_camera_3d()
	
	if camera:
		# Return position in front of camera on the ground
		var forward = -camera.global_transform.basis.z
		forward.y = 0  # Keep on ground level
		forward = forward.normalized()
		return camera.global_position + forward * 5
	
	return Vector3.ZERO
