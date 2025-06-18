#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import tempfile
import os
import sys
import socket

# Import whisper from conda environment
sys.path.append('/home/albus/miniforge3/envs/bark/lib/python3.11/site-packages')
import whisper

model = whisper.load_model("base")

class AudioHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            if self.path.startswith('/record/'):
                duration = self.path.split('/')[-1]
                print(f"📍 Starting {duration}s recording...")
                result = self.record_and_transcribe(int(duration))
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Content-Length', str(len(json.dumps(result))))
                self.end_headers()
                self.wfile.write(json.dumps(result).encode())
                print(f"✅ Sent response: {result}")
                
            elif self.path == '/health':
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ok"}).encode())
                
        except (BrokenPipeError, ConnectionResetError) as e:
            print(f"⚠️ Client disconnected early: {e}")
        except Exception as e:
            print(f"❌ Error: {e}")
    
    def record_and_transcribe(self, duration):
        try:
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
                temp_filename = tmp.name
            
            # Record using the working command, specifically targeting the 'pulse' device
            cmd = [
                '/bin/bash', '-c',
                f'PATH=/usr/bin:/bin:$PATH; /usr/bin/arecord -D pulse -f S16_LE -c 1 -r 16000 -d {duration} {temp_filename}'
            ]
            
            print(f"🎤 Recording for {duration} seconds...")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                return {"success": False, "error": f"Recording failed: {result.stderr}"}
            
            print(f"🔄 Transcribing audio...")
            # Transcribe with whisper
            result = model.transcribe(temp_filename)
            text = result["text"].strip().lower()
            
            # Cleanup
            os.unlink(temp_filename)
            
            print(f"✅ Transcribed: '{text}'")
            return {"success": True, "text": text}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def log_message(self, format, *args):
        # Custom logging
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == '__main__':
    # Set socket options to avoid "Address already in use" errors
    server = HTTPServer(('localhost', 5555), AudioHandler)
    server.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    print("🎤 Audio server running on http://localhost:5555")
    print("📍 Test with: curl http://localhost:5555/health")
    print("🎙️ Record with: curl http://localhost:5555/record/2")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Shutting down server...")
        server.shutdown()
