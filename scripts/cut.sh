#!/bin/bash
# YouTube Uploader - Cut video 60 seconds with DEBUG

source="./temp/source.mp4"
output="./temp/segment.mp4"
progress="./config/progress.json"

echo "🍂 Starting cut process..."

# Cek file exists
if [ ! -f "$source" ]; then
    echo "🍂 ERROR: Source video not found at $source"
    ls -la ./temp/
    exit 1
fi

# Cek ukuran file
filesize=$(stat -c%s "$source" 2>/dev/null || stat -f%z "$source" 2>/dev/null)
echo "💐 File size: $filesize bytes"

if [ "$filesize" -lt 1000000 ]; then
    echo "🍂 ERROR: File too small: ${filesize} bytes (should be >1MB)"
    exit 1
fi

# Cek durasi video
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$source" | cut -d. -f1)
echo "💐 Video duration: ${duration} seconds"

if [ -z "$duration" ] || [ "$duration" -lt 60 ]; then
    echo "🍂 ERROR: Invalid duration: $duration"
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$source"
    exit 1
fi

# Baca config
if [ ! -f "$progress" ]; then
    echo "🍂 ERROR: Progress file not found"
    exit 1
fi

current=$(jq -r '.current_segment' "$progress")
intro=$(jq -r '.intro_end' "$progress")
seg_duration=$(jq -r '.segment_duration' "$progress")

echo "💐 Config: current=$current, intro=$intro, seg_duration=$seg_duration"

start_time=$((intro + (current * seg_duration)))
start_formatted=$(printf "%02d:%02d:%02d" $((start_time/3600)) $(((start_time%3600)/60)) $((start_time%60)))

echo "🍂 Cutting segment $((current+1)) at $start_formatted..."

# Test with null output first
echo "🍂 Testing cut..."
ffmpeg -i "$source" -ss "$start_formatted" -t "$seg_duration" -f null - 2>&1 | head -20

# Actual cut
echo "🍂 Performing actual cut..."
ffmpeg -i "$source" -ss "$start_formatted" -t "$seg_duration" \
       -c:v libx264 -c:a aac -preset fast -y "$output" 2>&1

if [ $? -eq 0 ] && [ -f "$output" ]; then
    out_size=$(du -h "$output" | cut -f1)
    echo "💐 Cut successful: ${out_size}"
    ls -la "$output"
else
    echo "🍂 Cut failed!"
    exit 1
fi
