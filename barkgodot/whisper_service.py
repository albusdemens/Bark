#!/usr/bin/env python3
# whisper_service.py - Simple Python Whisper wrapper for Godot
import whisper
import sys
import json
import os

def transcribe_audio(audio_file_path):
    """Transcribe audio file using Whisper"""
    try:
        # Check if file exists
        if not os.path.exists(audio_file_path):
            return {
                "success": False,
                "error": f"Audio file not found: {audio_file_path}",
                "text": ""
            }
        
        # Check file size (should be > 1KB for valid audio)
        if os.path.getsize(audio_file_path) < 1000:
            return {
                "success": False,
                "error": "Audio file is too small or empty",
                "text": ""
            }
        
        # Load whisper model (downloads automatically first time)
        # Use base.en for good accuracy, or tiny.en for speed
        model = whisper.load_model("base.en")
        
        # Transcribe audio with specific options
        result = model.transcribe(
            audio_file_path,
            language="en",
            word_timestamps=False,
            verbose=False
        )
        
        # Clean up the transcribed text
        transcribed_text = result["text"].strip()
        
        # Return transcription
        return {
            "success": True,
            "text": transcribed_text,
            "language": result.get("language", "en"),
            "confidence": result.get("avg_logprob", 0.0)
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "text": ""
        }

if __name__ == "__main__":
    # Check command line arguments
    if len(sys.argv) != 2:
        print(json.dumps({
            "success": False, 
            "error": "Usage: python3 whisper_service.py <audio_file>"
        }))
        sys.exit(1)
    
    audio_file = sys.argv[1]
    result = transcribe_audio(audio_file)
    print(json.dumps(result))