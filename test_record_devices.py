# test_record_devices.py
import pyaudio
import wave
import sys

def test_device(device_index, device_name):
    print(f"\nTesting Device {device_index}: {device_name}")
    print("Speak into your headset for 3 seconds...")
    
    try:
        p = pyaudio.PyAudio()
        
        stream = p.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=16000,
            input=True,
            input_device_index=device_index,
            frames_per_buffer=1024
        )
        
        frames = []
        for i in range(0, int(16000 / 1024 * 3)):
            data = stream.read(1024)
            frames.append(data)
        
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Save test file
        filename = f"test_device_{device_index}.wav"
        wf = wave.open(filename, 'wb')
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(b''.join(frames))
        wf.close()
        
        print(f"✅ Success! Saved to {filename}")
        return True
        
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False

# Test the likely candidates
test_device(0, "Built-in mic")
test_device(4, "Possible headset")
test_device(6, "System default")