#!/bin/bash
# RANDOM CUT dengan frame extraction untuk Gemini

SOURCE="./temp/source.mp4"
OUTPUT="./temp/segment.mp4"
PROGRESS="./config/progress.json"
USED_CUTS="./config/used_cuts.txt"

echo "🍂 Starting random cut..."

if [ ! -f "$SOURCE" ]; then
    echo "🍂 ERROR: Source video not found"
    exit 1
fi

intro=$(jq -r '.intro_end' "$PROGRESS")
outro=$(jq -r '.outro_start' "$PROGRESS")
seg_duration=$(jq -r '.segment_duration' "$PROGRESS")
max_start=$((outro - seg_duration))

mkdir -p ./config ./temp
touch "$USED_CUTS"

used_count=$(wc -l < "$USED_CUTS")
total=$(jq -r '.total_segments' "$PROGRESS")

if [ "$used_count" -ge "$total" ]; then
    echo "✅ Semua segmen sudah diupload!"
    exit 0
fi

# Cari posisi cut yang belum dipakai
while true; do
    start_time=$((intro + (RANDOM % (max_start - intro + 1))))
    if ! grep -q "^$start_time$" "$USED_CUTS"; then
        echo "$start_time" >> "$USED_CUTS"
        break
    fi
done

start_formatted=$(printf "%02d:%02d:%02d" $((start_time/3600)) $(((start_time%3600)/60)) $((start_time%60)))
echo "🍂 Cutting segment unik di $start_formatted (durasi ${seg_duration}s)"

# Cut video
ffmpeg -y -ss "$start_formatted" -i "$SOURCE" -t "$seg_duration" \
    -c:v libx264 -c:a aac -preset fast -movflags +faststart "$OUTPUT" 2>&1

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    echo "💐 Cut successful: $(du -h "$OUTPUT" | cut -f1)"
    
    # Ambil 3 frame dari video untuk Gemini (detik 5, 15, 25)
    echo "🍂 Extracting frames untuk Gemini..."
    ffmpeg -i "$OUTPUT" -ss 5 -vframes 1 -y "./temp/frame1.jpg" 2>/dev/null
    ffmpeg -i "$OUTPUT" -ss 15 -vframes 1 -y "./temp/frame2.jpg" 2>/dev/null
    ffmpeg -i "$OUTPUT" -ss 25 -vframes 1 -y "./temp/frame3.jpg" 2>/dev/null
    echo "💐 Frames extracted"
else
    echo "🍂 Cut failed!"
    exit 1
fi
