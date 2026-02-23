#!/bin/bash
# YouTube Uploader - Presisi Cut dengan Validasi

source="./temp/source.mp4"
output="./temp/segment.mp4"
progress="./config/progress.json"

echo "🍂 Starting presisi cut..."

# Cek file exists
if [ ! -f "$source" ]; then
    echo "🍂 ERROR: Source video not found"
    exit 1
fi

# Cek durasi video asli
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$source" | cut -d. -f1)
echo "💐 Video duration: ${duration} seconds"

# Baca config
current=$(jq -r '.current_segment' "$progress")
intro=$(jq -r '.intro_end' "$progress")
outro=$(jq -r '.outro_start' "$progress")
seg_duration=$(jq -r '.segment_duration' "$progress")

# Validasi outro tidak melebihi durasi
if [ "$outro" -gt "$duration" ]; then
    echo "⚠️ Outro_start ($outro) > durasi video ($duration)"
    echo "⚠️ Menyesuaikan outro ke $((duration - 60))"
    outro=$((duration - 60))
fi

# Hitung start time
start_time=$((intro + (current * seg_duration)))
max_start=$((outro - seg_duration))

if [ "$start_time" -gt "$max_start" ]; then
    echo "⚠️ Start time $start_time melebihi batas, reset ke 0"
    start_time=$intro
    # Reset current segment di progress nanti
fi

start_formatted=$(printf "%02d:%02d:%02d" $((start_time/3600)) $(((start_time%3600)/60)) $((start_time%60)))
echo "🍂 Cutting segment $((current+1)) at $start_formatted..."

# Cut video
ffmpeg -i "$source" -ss "$start_formatted" -t "$seg_duration" \
       -c:v libx264 -c:a aac -preset fast -y "$output" 2>&1

if [ $? -eq 0 ] && [ -f "$output" ]; then
    out_size=$(du -h "$output" | cut -f1)
    echo "💐 Cut successful: ${out_size}"
else
    echo "🍂 Cut failed!"
    exit 1
fi
