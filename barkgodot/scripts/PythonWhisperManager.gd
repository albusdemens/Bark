extends Node

signal command_received(text: String)

var camera: Camera3D
var is_recording_in_progress: bool = false # Add a flag to prevent multiple simultaneous recordings

func _ready():
	print("🐍 Python Whisper Manager ready!")
	print("Commands: SPACE = record voice, T = test command")

func _input(event):
	if event is InputEventKey:
		# Check if the key was just pressed down and is not a repeat (echo) press
		if event.keycode == KEY_SPACE and event.is_pressed() and not event.is_echo():
			record_audio()
		elif event.keycode == KEY_T and event.is_pressed() and not event.is_echo():
			test_command()

func record_audio():
	# Prevent starting a new recording if one is already in progress
	if is_recording_in_progress:
		print("⚠️ Recording already in progress. Please wait.")
		return

	is_recording_in_progress = true # Set the flag to true
	print("🎤 Recording for 2 seconds...")
	
	# Create a new HTTP request with longer timeout
	var http = HTTPRequest.new()
	add_child(http)
	http.timeout = 12.0  # 12 seconds timeout (2 for recording + processing time)
	
	# Make the request
	var error = http.request("http://localhost:5555/record/2")
	
	if error != OK:
		print("❌ Request failed: ", error)
		http.queue_free()
		is_recording_in_progress = false # Reset the flag on error
		return
	
	# Wait for response
	var response = await http.request_completed
	
	# Parse response
	var response_code = response[1]
	var body = response[3]
	
	print("📡 Got response, code: ", response_code)
	
	if response_code == 200:
		var body_string = body.get_string_from_utf8()
		print("📤 Server said: ", body_string)
		
		var json = JSON.new()
		var parse_result = json.parse(body_string)
		
		if parse_result == OK:
			var data = json.data
			if data.has("success") and data.success:
				var text = data.get("text", "")
				print("🗣️ You said: '", text, "'")
				command_received.emit(text)
				process_command(text)
			else:
				print("❌ Error: ", data.get("error", "Unknown"))
		else:
			print("❌ JSON parse failed")
	else:
		print("❌ HTTP error: ", response_code)
	
	# Clean up
	http.queue_free()
	is_recording_in_progress = false # Reset the flag after completion

func test_command():
	var command = "come here"
	print("🧪 Test command: '", command, "'")
	command_received.emit(command)
	process_command(command)

func process_command(text: String):
	text = text.to_lower().strip_edges()
	
	var dog = get_tree().get_first_node_in_group("dog")
	if not dog:
		print("❌ No dog found in scene!")
		return
	
	var player_pos = get_player_position()
	
	# Movement commands. Commands are divided in three tiers:
	# 1. Come here, stay, sit, go 
	# 2. Drop it, find it, get it, leave it
	# 3. Up, down, inside
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
		var random_pos = player_pos + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		dog.move_to_position(random_pos)
	else:                                                                                                                                                                                                        
		print("❓ Unknown command: ", text)

func get_player_position() -> Vector3:
	if not camera:
		camera = get_viewport().get_camera_3d()
	
	if camera:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		return camera.global_position + forward * 5
	
	return Vector3.ZERO
