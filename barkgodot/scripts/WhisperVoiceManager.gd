extends Node
# AutoLoad singleton - replace SimpleVoiceManager with this

signal command_received(text: String)

var is_listening: bool = false
var is_recording: bool = false
var camera: Camera3D

# Audio recording
var audio_stream_microphone: AudioStreamMicrophone
var audio_stream_player: AudioStreamPlayer
var recorded_audio: PackedFloat32Array
var sample_rate: int = 16000  # Whisper prefers 16kHz

# Whisper server settings (we'll run whisper.cpp server locally)
var whisper_url: String = "http://localhost:8080/inference"
var recording_duration: float = 3.0  # seconds to record

func _ready():
	print("🎤 Whisper Voice Manager ready!")
	print("Commands: SPACE = record voice, T = test command")
	setup_audio_recording()

func setup_audio_recording():
	# Create microphone stream
	audio_stream_microphone = AudioStreamMicrophone.new()
	
	# Create audio player for recording
	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.stream = audio_stream_microphone
	add_child(audio_stream_player)
	
	print("🔧 Audio recording setup complete")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if not is_listening:
				start_real_listening()
		elif event.keycode == KEY_T:
			test_command()

func start_real_listening():
	if is_listening:
		return
	
	print("🎤 Recording audio for ", recording_duration, " seconds...")
	is_listening = true
	is_recording = true
	
	# Clear previous recording
	recorded_audio.clear()
	
	# Start recording
	audio_stream_player.play()
	
	# Record for specified duration
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = recording_duration
	timer.one_shot = true
	timer.timeout.connect(_on_recording_complete)
	timer.start()

func _on_recording_complete():
	print("🔇 Recording complete, processing with Whisper...")
	is_recording = false
	audio_stream_player.stop()
	
	# Get the recorded audio data
	captured_audio_data()
	
	is_listening = false

func captured_audio_data():
	# Get audio buffer from AudioServer
	var playback = audio_stream_player.get_stream_playback()
	if not playback:
		print("❌ Failed to get audio playback")
		return
	
	# For now, we'll simulate the audio processing
	# In a full implementation, you'd capture actual audio frames here
	print("🔄 Processing audio with Whisper...")
	
	# Send audio to Whisper server
	send_audio_to_whisper()

func send_audio_to_whisper():
	# Create HTTP request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_whisper_response)
	
	# For now, we'll use a simple text endpoint since getting raw audio 
	# capture working requires more complex setup
	# In production, you'd send the actual WAV/audio data
	
	# Simulate sending audio file (you'd replace this with actual audio data)
	var headers = ["Content-Type: application/json"]
	var request_body = JSON.stringify({
		"text": "Hello whisper",  # This would be replaced with audio data
		"language": "en"
	})
	
	print("📡 Sending audio to Whisper server...")
	var error = http_request.request(whisper_url, headers, HTTPClient.METHOD_POST, request_body)
	
	if error != OK:
		print("❌ Failed to connect to Whisper server: ", error)
		print("💡 Make sure whisper.cpp server is running on localhost:8080")
		# Fallback to simulated recognition
		simulate_whisper_response()

func _on_whisper_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		print("❌ Whisper server error: ", response_code)
		simulate_whisper_response()
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		print("❌ Failed to parse Whisper response")
		simulate_whisper_response()
		return
	
	var whisper_data = json.data
	var transcribed_text = ""
	
	# Parse Whisper response (format depends on whisper.cpp server setup)
	if whisper_data.has("text"):
		transcribed_text = whisper_data["text"]
	elif whisper_data.has("transcription"):
		transcribed_text = whisper_data["transcription"]
	else:
		print("❌ Unexpected Whisper response format")
		simulate_whisper_response()
		return
	
	print("🗣️ Whisper heard: '", transcribed_text, "'")
	command_received.emit(transcribed_text)
	process_command(transcribed_text)

func simulate_whisper_response():
	# Fallback when Whisper server isn't available
	var test_commands = [
		"come here",
		"sit down", 
		"stay there",
		"go over there"
	]
	
	var command = test_commands[randi() % test_commands.size()]
	print("🤖 Simulated Whisper: '", command, "'")
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
	
	# Parse commands
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
