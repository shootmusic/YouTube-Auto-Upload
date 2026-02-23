#!/bin/bash
# YouTube Uploader - Download from Drive (Fixed for GitHub Actions)

VIDEO_ID="1NCYonDGrVwHsSXvN_6gr6GEWWge3HaHy"
OUTPUT_DIR="./temp"
mkdir -p $OUTPUT_DIR

echo "🍂 Downloading video with wget..."

# Method 1: pake wget dengan confirmation token
wget --quiet --save-cookies /tmp/cookies.txt \
     --keep-session-cookies \
     --no-check-certificate \
     "https://docs.google.com/uc?export=download&id=${VIDEO_ID}" -O /tmp/tmp.html

CONFIRM=$(cat /tmp/tmp.html | grep -o 'confirm=[^"&]*' | cut -d '=' -f2)

if [ -n "$CONFIRM" ]; then
    wget --load-cookies /tmp/cookies.txt \
         "https://docs.google.com/uc?export=download&confirm=${CONFIRM}&id=${VIDEO_ID}" \
         -O "${OUTPUT_DIR}/source.mp4"
else
    # Method 2: direct download (kalo file kecil)
    wget "https://drive.google.com/uc?export=download&id=${VIDEO_ID}" \
         -O "${OUTPUT_DIR}/source.mp4"
fi

rm -f /tmp/cookies.txt /tmp/tmp.html

if [ -f "${OUTPUT_DIR}/source.mp4" ] && [ -s "${OUTPUT_DIR}/source.mp4" ]; then
    FILESIZE=$(du -h "${OUTPUT_DIR}/source.mp4" | cut -f1)
    echo "💐 Download successful (${FILESIZE})"
    
    # Get video duration
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${OUTPUT_DIR}/source.mp4" | cut -d. -f1)
    if [ -f "./config/progress.json" ]; then
        jq --arg dur "$DURATION" '.video_duration = $dur' ./config/progress.json > tmp.json && mv tmp.json ./config/progress.json
    fi
else
    echo "🍂 Download failed!"
    exit 1
fi
