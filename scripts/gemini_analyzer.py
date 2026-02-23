#!/usr/bin/env python3
import os
import json
import base64
import requests
import subprocess
import sys

GEMINI_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.5-pro"

if not GEMINI_KEY:
    print("🍂 GEMINI_API_KEY not set!")
    sys.exit(1)

def analyze_video():
    """Generate judul & deskripsi berdasarkan isi video"""
    
    # Extract frame from video
    subprocess.run("ffmpeg -i ./temp/segment.mp4 -ss 5 -vframes 1 -y ./temp/frame.jpg 2>/dev/null", shell=True)
    
    if not os.path.exists("./temp/frame.jpg"):
        print("🍂 Failed to extract frame")
        return fallback_metadata()
    
    with open("./temp/frame.jpg", "rb") as f:
        frame_base64 = base64.b64encode(f.read()).decode()
    
    # Read current segment
    with open("./config/progress.json", "r") as f:
        progress = json.load(f)
    segment_num = progress.get("current_segment", 0) + 1
    
    prompt = f"""
    Analisis video pendek 1 menit ini dari film Hot Young Bloods (segmen ke-{segment_num} dari 112).
    
    Berdasarkan frame yang diberikan:
    1. Buat judul yang menarik, spesifik, dan SEO friendly dalam bahasa Indonesia
    2. Buat deskripsi 2-3 kalimat yang menjelaskan adegan ini
    3. Berikan 5 tags yang relevan (bahasa Indonesia/Inggris)
    
    Format RESPON HARUS JSON:
    {{
        "title": "...",
        "description": "...",
        "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
    }}
    """
    
    try:
        response = requests.post(
            f"https://generativelanguage.googleapis.com/v1/models/{MODEL}:generateContent?key={GEMINI_KEY}",
            headers={"Content-Type": "application/json"},
            json={
                "contents": [{
                    "parts": [
                        {"text": prompt},
                        {"inline_data": {"mime_type": "image/jpeg", "data": frame_base64}}
                    ]
                }]
            },
            timeout=30
        )
        
        result = response.json()
        
        if "candidates" in result and len(result["candidates"]) > 0:
            text = result["candidates"][0]["content"]["parts"][0]["text"]
            # Extract JSON from response
            json_start = text.find("{")
            json_end = text.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                metadata = json.loads(text[json_start:json_end])
                
                with open("./temp/metadata.json", "w") as f:
                    json.dump(metadata, f, indent=2)
                print("💐 AI analysis successful")
                return metadata
    except Exception as e:
        print(f"🍂 AI analysis error: {e}")
    
    return fallback_metadata(segment_num)

def fallback_metadata(segment_num=1):
    """Fallback jika Gemini gagal"""
    fallback = {
        "title": f"Hot Young Bloods - Part {segment_num}",
        "description": "Cuplikan seru dari film Hot Young Bloods",
        "tags": ["filmkorea", "hotyoungbloods", "korea", "movie", "clip"]
    }
    with open("./temp/metadata.json", "w") as f:
        json.dump(fallback, f)
    print("🍂 Using fallback metadata")
    return fallback

if __name__ == "__main__":
    analyze_video()
