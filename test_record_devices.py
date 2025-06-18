# test_record_devices.py
import pyaudio
import wave
import sys

def test_device(device_index, device_name):
    print(f"\nTesting Device {device_index}: {device_name}")
    print("Speak into your microphone for 3 seconds...") # Changed 'headset' to 'microphone'

    try:
        p = pyaudio.PyAudio()

        # Get device info to check maxInputChannels and defaultSampleRate
        info = p.get_device_info_by_index(device_index)
        channels = min(info['maxInputChannels'], 1) # Use 1 channel for recording, or max available if less than 1
        rate = int(info['defaultSampleRate']) # Use the device's default sample rate

        if channels == 0:
            print(f"❌ Device {device_index} ({device_name}) has no input channels. Skipping.")
            p.terminate()
            return False

        stream = p.open(
            format=pyaudio.paInt16,
            channels=channels, # Use the determined number of channels
            rate=rate,         # Use the device's default sample rate
            input=True,
            input_device_index=device_index,
            frames_per_buffer=4096
        )

        frames = []
        # Adjust range for 3 seconds based on actual rate
        for i in range(0, int(rate / 1024 * 3)):
            data = stream.read(1024)
            frames.append(data)

        stream.stop_stream()
        stream.close()
        p.terminate()

        # Save test file
        filename = f"test_device_{device_index}_{device_name.replace(' ', '_').replace('-', '')}.wav"
        wf = wave.open(filename, 'wb')
        wf.setnchannels(channels) # Set channels based on what was used for recording
        wf.setsampwidth(p.get_sample_size(pyaudio.paInt16)) # Use PyAudio's method for sample width
        wf.setframerate(rate)
        wf.writeframes(b''.join(frames))
        wf.close()

        print(f"✅ Success! Saved to {filename}")
        return True

    except Exception as e:
        print(f"❌ Failed for device {device_index} ({device_name}): {e}")
        return False

# Test the most likely candidates for your built-in microphone
print("Starting microphone tests based on your device list.")
#test_device(0, "sof-hda-dsp_hw0_0") # Likely built-in mic
#test_device(4, "sof-hda-dsp_hw0_6") # Another strong candidate for built-in mic
#test_device(6, "sysdefault")        # System default, might capture from built-in
test_device(10, "pulse")
