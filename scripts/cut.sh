#!/bin/bash
# YouTube Uploader - Cut video 60 seconds

source="./temp/source.mp4"
output="./temp/segment.mp4"
progress="./config/progress.json"

if [ ! -f "$source" ]; then
    echo "🍂 Source video not found!"
    exit 1
fi

current=$(jq -r '.current_segment' $progress)
intro=$(jq -r '.intro_end' $progress)
duration=$(jq -r '.segment_duration' $progress)

start_time=$((intro + (current * duration)))
start_formatted=$(printf "%02d:%02d:%02d" $((start_time/3600)) $(((start_time%3600)/60)) $((start_time%60)))

echo "🍂 Cutting segment $((current+1)) at $start_formatted..."

ffmpeg -i "$source" -ss "$start_formatted" -t "$duration" \
       -c:v libx264 -c:a aac -preset fast -y "$output" 2>/dev/null

if [ $? -eq 0 ] && [ -f "$output" ]; then
    filesize=$(du -h "$output" | cut -f1)
    echo "💐 Cut successful: ${filesize}"
else
    echo "🍂 Cut failed!"
    exit 1
fi
