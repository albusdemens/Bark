# test_audio_devices.py
import pyaudio

p = pyaudio.PyAudio()

print("Available audio devices:")
print("-" * 50)

for i in range(p.get_device_count()):
    info = p.get_device_info_by_index(i)
    print(f"Device {i}: {info['name']}")
    print(f"  - Channels: {info['maxInputChannels']} in, {info['maxOutputChannels']} out")
    print(f"  - Default Sample Rate: {info['defaultSampleRate']}")
    print()

p.terminate()