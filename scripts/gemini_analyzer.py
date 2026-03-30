#!/usr/bin/env python3
import os
import json
import base64
import requests
import sys

GEMINI_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.5-pro"

def analyze_video():
    """Generate judul UNIK + deskripsi + tags berdasarkan frame video"""
    
    # Baca posisi cut dari progress
    with open("./config/progress.json", "r") as f:
        progress = json.load(f)
    
    with open("./config/used_cuts.txt", "r") as f:
        used_cuts = [int(line.strip()) for line in f if line.strip()]
    
    current_cut = used_cuts[-1] if used_cuts else 0
    segment_num = len(used_cuts)
    
    # Encode frame ke base64
    frames = []
    for i in range(1, 4):
        frame_path = f"./temp/frame{i}.jpg"
        if os.path.exists(frame_path):
            with open(frame_path, "rb") as f:
                frames.append(base64.b64encode(f.read()).decode())
    
    if not frames:
        # Fallback kalo gagal extract frame
        return {
            "title": f"Big Mouth - Scene {segment_num}",
            "description": "Cuplikan seru dari Big Mouth Season 1 Episode 1",
            "tags": ["bigmouth", "netflix", "komedi", "animasi", "scene"]
        }
    
    prompt = f"""
    Analisis video pendek 1 menit ini dari serial Big Mouth Season 1 Episode 1 (segmen ke-{segment_num}).
    
    Berdasarkan 3 frame yang diberikan:
    1. Buat JUDUL yang UNIK, MENARIK, dan SEO friendly dalam BAHASA INDONESIA (max 60 karakter)
    2. Buat DESKRIPSI 2-3 kalimat dalam BAHASA INDONESIA yang menjelaskan adegan ini
    3. Berikan 5 TAGS yang relevan (campuran Indonesia/Inggris)
    
    JANGAN PAKAI JUDUL GENERIK SEPERTI "Big Mouth Part X"!
    Buat judul yang spesifik sesuai ADEGAN yang terlihat.
    
    Format RESPON HARUS JSON:
    {{
        "title": "...",
        "description": "...",
        "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
    }}
    """
    
    try:
        # Kirim 3 frame sekaligus ke Gemini
        parts = [{"text": prompt}]
        for frame_b64 in frames:
            parts.append({"inline_data": {"mime_type": "image/jpeg", "data": frame_b64}})
        
        response = requests.post(
            f"https://generativelanguage.googleapis.com/v1/models/{MODEL}:generateContent?key={GEMINI_KEY}",
            headers={"Content-Type": "application/json"},
            json={"contents": [{"parts": parts}]},
            timeout=30
        )
        
        result = response.json()
        
        if "candidates" in result and len(result["candidates"]) > 0:
            text = result["candidates"][0]["content"]["parts"][0]["text"]
            # Extract JSON
            json_start = text.find("{")
            json_end = text.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                metadata = json.loads(text[json_start:json_end])
                
                with open("./temp/metadata.json", "w") as f:
                    json.dump(metadata, f, indent=2)
                print(f"💐 AI generated: {metadata.get('title')}")
                return metadata
    except Exception as e:
        print(f"🍂 Gemini error: {e}")
    
    # Fallback
    fallback = {
        "title": f"Momen Kocak Big Mouth - Scene {segment_num}",
        "description": "Cuplikan seru dari Big Mouth Season 1 Episode 1. Animasi komedi dewasa yang bikin ngakak!",
        "tags": ["bigmouth", "netflix", "animasi", "komedi", "adegan"]
    }
    with open("./temp/metadata.json", "w") as f:
        json.dump(fallback, f)
    print("🍂 Using fallback metadata")
    return fallback

if __name__ == "__main__":
    analyze_video()
