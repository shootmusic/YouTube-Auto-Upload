#!/usr/bin/env python3
import os
import json
import pickle
import requests
from datetime import datetime
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request
import sys

WORK_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKEN_PATH = f"{WORK_DIR}/token.pickle"
TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

def send_telegram(message):
    if not TELEGRAM_TOKEN or not CHAT_ID:
        return
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    try:
        requests.post(url, json={"chat_id": CHAT_ID, "text": f"YouTube Uploader: {message}"}, timeout=10)
    except:
        pass

def get_youtube_service():
    if not os.path.exists(TOKEN_PATH):
        print("🍂 token.pickle not found!")
        send_telegram("🍂 token.pickle not found!")
        return None
    
    with open(TOKEN_PATH, 'rb') as token:
        creds = pickle.load(token)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            print("🍂 Invalid credentials")
            return None
    return build('youtube', 'v3', credentials=creds)

def upload_video():
    # Check if segment exists
    if not os.path.exists("./temp/segment.mp4"):
        print("🍂 segment.mp4 not found!")
        send_telegram("🍂 segment.mp4 not found!")
        return False
    
    # Read metadata from Gemini
    metadata = {"title": "Hot Young Bloods", "description": "Auto upload", "tags": ["movie"]}
    if os.path.exists("./temp/metadata.json"):
        with open("./temp/metadata.json", "r") as f:
            metadata = json.load(f)
    
    # Read progress
    with open("./config/progress.json", "r") as f:
        progress = json.load(f)
    segment = progress.get("current_segment", 0) + 1
    
    title = metadata.get("title", f"Hot Young Bloods Part {segment}")
    description = metadata.get("description", f"Auto upload from YouTube Uploader Bot - Part {segment}")
    tags = metadata.get("tags", ["filmkorea", "movie"])
    
    youtube = get_youtube_service()
    if not youtube:
        return False
    
    body = {
        'snippet': {
            'title': title[:100],  # YouTube max 100 chars
            'description': description[:5000],
            'tags': tags[:500],
            'categoryId': '1'  # Film & Animation
        },
        'status': {
            'privacyStatus': 'public',
            'selfDeclaredMadeForKids': False
        }
    }
    
    try:
        print("🍂 Uploading to YouTube...")
        media = MediaFileUpload("./temp/segment.mp4", mimetype='video/mp4', resumable=True)
        request = youtube.videos().insert(part='snippet,status', body=body, media_body=media)
        response = request.execute()
        
        video_id = response['id']
        video_url = f"https://youtu.be/{video_id}"
        
        # Update progress
        progress['current_segment'] += 1
        progress['uploaded_count'] += 1
        progress['last_upload'] = datetime.now().isoformat()
        
        with open("./config/progress.json", "w") as f:
            json.dump(progress, f, indent=2)
        
        # Notifikasi
        remaining = progress['total_segments'] - progress['uploaded_count']
        send_telegram(f"💐 Uploaded Part {segment}: {title}\n{remaining} remaining")
        
        # Backup progress
        backup_file = f"./backup/progress_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(backup_file, "w") as f:
            json.dump(progress, f)
        
        print(f"💐 Upload successful: {video_url}")
        return True
        
    except Exception as e:
        print(f"🍂 Upload error: {e}")
        send_telegram(f"🍂 Upload failed: {str(e)[:100]}")
        return False

if __name__ == "__main__":
    success = upload_video()
    sys.exit(0 if success else 1)
