#!/usr/bin/env python3
import subprocess
import sys
import json
import os

def record_audio(duration, filename):
    try:
        # Break out of conda environment completely
        cmd = [
            '/usr/bin/env', '-i',  # -i flag clears all environment
            'PATH=/usr/bin:/bin',
            'HOME=' + os.path.expanduser('~'),
            '/usr/bin/arecord',
            '-D', 'plughw:0,0',
            '-f', 'S16_LE',
            '-c', '1',
            '-r', '16000',
            '-d', duration,
            filename
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            if os.path.exists(filename) and os.path.getsize(filename) > 0:
                return {"success": True, "filename": filename, "size": os.path.getsize(filename)}
            else:
                return {"success": False, "error": "No audio recorded"}
        else:
            return {"success": False, "error": f"Recording failed: {result.stderr}"}
            
    except Exception as e:
        return {"success": False, "error": f"Exception: {str(e)}"}

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(json.dumps({"success": False, "error": "Usage: record_audio.py duration filename"}))
        sys.exit(1)
    
    try:
        duration = sys.argv[1]
        filename = sys.argv[2]
        
        result = record_audio(duration, filename)
        print(json.dumps(result))
        
    except Exception as e:
        print(json.dumps({"success": False, "error": f"Script error: {str(e)}"}))
        sys.exit(1)