#!/usr/bin/env python3
import os
import json
import base64
import requests
import subprocess

GEMINI_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.5-pro"

def analyze_video():
    # Extract frame
    subprocess.run("ffmpeg -i ./temp/segment.mp4 -ss 5 -vframes 1 -y ./temp/frame.jpg 2>/dev/null", shell=True)
    
    with open("./temp/frame.jpg", "rb") as f:
        frame_base64 = base64.b64encode(f.read()).decode()
    
    with open("./config/progress.json", "r") as f:
        progress = json.load(f)
    segment_num = progress.get("current_segment", 0) + 1
    
    prompt = f"""
    Analisis video pendek 1 menit ini dari film Hot Young Bloods (segmen ke-{segment_num} dari 112).
    
    Berdasarkan frame:
    1. Buat judul menarik & SEO friendly dalam Bahasa Indonesia
    2. Deskripsi 2-3 kalimat
    3. 5 tags relevan
    
    Format JSON:
    {{
        "title": "...",
        "description": "...",
        "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"]
    }}
    """
    
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
    try:
        text = result["candidates"][0]["content"]["parts"][0]["text"]
        json_start = text.find("{")
        json_end = text.rfind("}") + 1
        if json_start >= 0 and json_end > json_start:
            metadata = json.loads(text[json_start:json_end])
            with open("./temp/metadata.json", "w") as f:
                json.dump(metadata, f)
            print("💐 AI analysis sukses")
            return metadata
    except:
        fallback = {
            "title": f"Hot Young Bloods - Part {segment_num}",
            "description": "Cuplikan seru dari film Hot Young Bloods",
            "tags": ["filmkorea", "hotyoungbloods", "korea", "movie", "clip"]
        }
        with open("./temp/metadata.json", "w") as f:
            json.dump(fallback, f)
        print("🍂 Pakai fallback metadata")
        return fallback

if __name__ == "__main__":
    analyze_video()
