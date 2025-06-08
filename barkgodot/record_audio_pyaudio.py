#!/usr/bin/env python3
# record_audio_pyaudio.py - Pure Python audio recording (no arecord dependency)
import sys
import json
import os
import wave

def record_audio_python(duration=3, output_file="temp_audio.wav", sample_rate=16000):
    """Record audio using pure Python (pyaudio)"""
    try:
        import pyaudio
    except ImportError:
        return {
            "success": False,
            "error": "pyaudio not installed. Install with: pip install pyaudio"
        }
    
    try:
        # Audio recording parameters
        chunk = 1024  # Record in chunks
        format = pyaudio.paInt16  # 16-bit resolution
        channels = 1  # Mono
        
        # Initialize PyAudio
        p = pyaudio.PyAudio()
        
        # Open stream
        stream = p.open(format=format,
                       channels=channels,
                       rate=sample_rate,
                       input=True,
                       frames_per_buffer=chunk)
        
        print(f"🎤 Recording {duration} seconds...")
        
        frames = []
        
        # Record for specified duration
        for i in range(0, int(sample_rate / chunk * duration)):
            data = stream.read(chunk)
            frames.append(data)
        
        # Stop and close the stream
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Save the recorded data as a WAV file
        wf = wave.open(output_file, 'wb')
        wf.setnchannels(channels)
        wf.setsampwidth(p.get_sample_size(format))
        wf.setframerate(sample_rate)
        wf.writeframes(b''.join(frames))
        wf.close()
        
        # Check if file was created successfully
        if os.path.exists(output_file) and os.path.getsize(output_file) > 1000:
            return {
                "success": True,
                "file": output_file,
                "duration": duration,
                "size_bytes": os.path.getsize(output_file),
                "message": "Audio recorded successfully with PyAudio"
            }
        else:
            return {
                "success": False,
                "error": "Audio file is empty or too small"
            }
            
    except Exception as e:
        return {
            "success": False,
            "error": f"PyAudio recording failed: {str(e)}"
        }

if __name__ == "__main__":
    duration = 3
    output_file = "temp_audio.wav"
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        try:
            duration = int(float(sys.argv[1]))
        except ValueError:
            print(json.dumps({"success": False, "error": "Invalid duration"}))
            sys.exit(1)
    
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    
    result = record_audio_python(duration, output_file)
    print(json.dumps(result))