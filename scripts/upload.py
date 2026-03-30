#!/usr/bin/env python3
import os, json, pickle, requests
from datetime import datetime
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request

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
        return None
    with open(TOKEN_PATH, 'rb') as token:
        creds = pickle.load(token)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            return None
    return build('youtube', 'v3', credentials=creds)

def upload_video():
    if not os.path.exists("./temp/segment.mp4"):
        return False

    # Read metadata
    metadata = {"title": "Hot Young Bloods", "description": "Auto upload", "tags": ["movie"]}
    if os.path.exists("./temp/metadata.json"):
        with open("./temp/metadata.json", "r") as f:
            metadata = json.load(f)

    # Baca used_cuts.txt untuk hitung segment number
    used_cuts = "./config/used_cuts.txt"
    if os.path.exists(used_cuts):
        with open(used_cuts, "r") as f:
            segment = len(f.readlines())
    else:
        segment = 1

    title = metadata.get("title", f"Big Mouth Part {segment}")
    description = metadata.get("description", f"Auto upload - Part {segment}")
    tags = metadata.get("tags", ["bigmouth", "netflix"])

    youtube = get_youtube_service()
    if not youtube:
        return False

    body = {
        'snippet': {
            'title': title[:100],
            'description': description[:5000],
            'tags': tags[:500],
            'categoryId': '1'
        },
        'status': {
            'privacyStatus': 'public',
            'selfDeclaredMadeForKids': False
        }
    }

    try:
        media = MediaFileUpload("./temp/segment.mp4", mimetype='video/mp4', resumable=True)
        request = youtube.videos().insert(part='snippet,status', body=body, media_body=media)
        response = request.execute()

        video_id = response['id']
        video_url = f"https://youtu.be/{video_id}"

        # Kirim notifikasi Telegram pake title dari Gemini
        send_telegram(f"🎉 Uploaded Part {segment}: {title}")

        print(f"💐 Upload successful: {video_url}")
        return True

    except Exception as e:
        print(f"🍂 Upload error: {e}")
        return False

if __name__ == "__main__":
    success = upload_video()
    import sys
    sys.exit(0 if success else 1)
