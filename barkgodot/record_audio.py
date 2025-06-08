#!/usr/bin/env python3
# record_audio.py - Simple audio recording using arecord (Linux/ALSA)
import subprocess
import sys
import json
import os
import time

def record_audio(duration=3, output_file="temp_audio.wav", sample_rate=16000):
    """Record audio using arecord (Linux/ALSA)
    
    Args:
        duration: Recording duration in seconds (integer)
        output_file: Output WAV file path
        sample_rate: Audio sample rate (16000 recommended for Whisper)
    """
    try:
        # Check if arecord is available
        result = subprocess.run(['which', 'arecord'], capture_output=True)
        if result.returncode != 0:
            return {
                "success": False,
                "error": "arecord not found. Install with: sudo apt install alsa-utils"
            }
        
        # Remove existing file if it exists
        if os.path.exists(output_file):
            os.remove(output_file)
        
        # Record audio using arecord
        cmd = [
            'arecord',
            '-f', 'S16_LE',           # 16-bit little-endian
            '-c', '1',                # Mono
            '-r', str(sample_rate),   # Sample rate (16kHz for Whisper)
            '-t', 'wav',              # WAV format
            '-d', str(int(duration)), # Duration in seconds (must be integer)
            output_file
        ]
        
        print(f"🎤 Recording {int(duration)} seconds of audio to {output_file}...")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Check if file was created and has reasonable content
            if os.path.exists(output_file) and os.path.getsize(output_file) > 1000:
                return {
                    "success": True,
                    "file": output_file,
                    "duration": duration,
                    "size_bytes": os.path.getsize(output_file),
                    "message": "Audio recorded successfully"
                }
            else:
                return {
                    "success": False,
                    "error": "Audio file is empty or too small. Check microphone connection."
                }
        else:
            return {
                "success": False,
                "error": f"arecord failed: {result.stderr.strip()}"
            }
            
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

if __name__ == "__main__":
    duration = 3
    output_file = "temp_audio.wav"
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        try:
            duration = int(float(sys.argv[1]))  # Convert to int for arecord
        except ValueError:
            print(json.dumps({"success": False, "error": "Invalid duration"}))
            sys.exit(1)
    
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    
    result = record_audio(duration, output_file)
    print(json.dumps(result))