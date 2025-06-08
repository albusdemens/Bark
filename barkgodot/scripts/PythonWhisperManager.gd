extends Node
# AutoLoad singleton - Alternative simple approach

signal command_received(text: String)

var is_listening: bool = false
var camera: Camera3D

func _ready():
	print("🐍 Python Whisper Manager ready!")
	print("Commands: SPACE = record voice, T = test command")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_python_whisper()
		elif event.keycode == KEY_T:
			test_command()

func start_python_whisper():
	if is_listening:
		return
	
	print("🎤 Recording audio with Python Whisper...")
	is_listening = true
	
	# Record audio to temporary file
	record_audio_to_file()

func record_audio_to_file():
	print("🎤 Recording audio with Python script...")
	
	# Call Python audio recording script
	var output = []
	var record_script_path = ProjectSettings.globalize_path("res://record_audio.py")
	var duration = "3"  # 3 seconds (arecord needs integer)
	var audio_filename = "temp_audio.wav"
	
	var exit_code = OS.execute("python3", [record_script_path, duration, audio_filename], output)
	
	if exit_code == 0 and output.size() > 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		
		if parse_result == OK:
			var result = json.data
			if result.get("success", false):
				print("✅ Audio recorded successfully")
				# Now send to Whisper for transcription
				call_whisper_on_recorded_audio(audio_filename)
			else:
				print("❌ Recording failed: ", result.get("error", "Unknown error"))
				simulate_fallback()
		else:
			print("❌ Failed to parse recording response")
			simulate_fallback()
	else:
		print("❌ Audio recording script failed (exit code: ", exit_code, ")")
		if output.size() > 0:
			print("Recording output: ", output[0])
		simulate_fallback()

func call_whisper_on_recorded_audio(audio_filename: String):
	print("📁 Sending recorded audio to Python Whisper...")
	
	# Call Python Whisper script
	var output = []
	var whisper_script_path = ProjectSettings.globalize_path("res://whisper_service.py")
	var audio_path = ProjectSettings.globalize_path("res://" + audio_filename)
	
	var exit_code = OS.execute("python3", [whisper_script_path, audio_path], output)
	
	if exit_code == 0 and output.size() > 0:
		var json = JSON.new()
		var parse_result = json.parse(output[0])
		
		if parse_result == OK:
			var result = json.data
			if result.get("success", false):
				var transcribed_text = result.get("text", "")
				print("🗣️ Python Whisper heard: '", transcribed_text, "'")
				command_received.emit(transcribed_text)
				process_command(transcribed_text)
			else:
				print("❌ Whisper error: ", result.get("error", "Unknown error"))
				simulate_fallback()
		else:
			print("❌ Failed to parse Whisper response")
			simulate_fallback()
	else:
		print("❌ Python Whisper failed (exit code: ", exit_code, "), using fallback")
		if output.size() > 0:
			print("Whisper output: ", output[0])
		simulate_fallback()
	
	is_listening = false

func simulate_fallback():
	# Fallback when Python/Whisper fails
	var test_commands = ["come here", "sit down", "stay there", "go over there"]
	var command = test_commands[randi() % test_commands.size()]
	print("🤖 Fallback command: '", command, "'")
	command_received.emit(command)
	process_command(command)

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
	
	# Movement commands
	if "come" in text or "here" in text:
		print("📍 Calling dog to come here")
		dog.come_here(player_pos)
	elif "follow" in text or "follow me" in text:
		print("👥 Dog will follow you")
		dog.follow()
	elif "go" in text or "there" in text:
		print("👉 Telling dog to go somewhere")
		var random_pos = player_pos + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		dog.move_to_position(random_pos)
	
	# Position commands
	elif "sit" in text:
		print("🐕 Telling dog to sit")
		dog.sit()
	elif "stay" in text or "wait" in text:
		print("✋ Telling dog to stay")
		dog.stay()
	elif "release" in text or "free" in text or "okay" in text:
		print("🆓 Releasing dog")
		dog.release()
	
	# Activity commands
	elif "play" in text or "playful" in text:
		print("🎾 Time to play!")
		dog.play()
	elif "good" in text or "boy" in text or "girl" in text:
		print("🎉 Good dog!")
		dog.good_boy()
	
	# Status commands
	elif "status" in text or "how are you" in text:
		if dog.has_method("get_status"):
			print("📊 Dog status: ", dog.get_status())
		else:
			print("🐕 Dog is doing well!")
	
	else:
		print("❓ Unknown command: ", text)
		print("💡 Try: come here, sit, stay, follow me, play, good boy")

func get_player_position() -> Vector3:
	if not camera:
		camera = get_viewport().get_camera_3d()
	
	if camera:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		return camera.global_position + forward * 5
	
	return Vector3.ZERO
