#!/bin/bash
# YouTube Uploader - Presisi Cut dengan Validasi

SOURCE="./temp/source.mp4"
OUTPUT="./temp/segment.mp4"
PROGRESS="./config/progress.json"

echo "🍂 Starting presisi cut..."

# ── Validasi source ─────────────────────────────────────────────────
if [ ! -f "$SOURCE" ]; then
    echo "🍂 ERROR: Source video not found: $SOURCE"
    exit 1
fi

# ── BACA CURRENT DARI FILE (Langsung, jangan pake variable global) ─
current=$(jq -r '.current_segment' "$PROGRESS")
intro=$(jq -r '.intro_end' "$PROGRESS")
outro=$(jq -r '.outro_start' "$PROGRESS")
seg_duration=$(jq -r '.segment_duration' "$PROGRESS")

echo "📋 Config — current: $current | intro: $intro | outro: $outro"

# ── Hitung start time ───────────────────────────────────────────────
start_time=$((intro + (current * seg_duration)))
start_formatted=$(printf "%02d:%02d:%02d" $((start_time/3600)) $(((start_time%3600)/60)) $((start_time%60)))

echo "🍂 Cutting segment $((current + 1)) | Start: $start_formatted"

# ── FFmpeg cut ──────────────────────────────────────────────────────
ffmpeg -y -ss "$start_formatted" -i "$SOURCE" -t "$seg_duration" \
       -c:v libx264 -c:a aac -preset fast -movflags +faststart "$OUTPUT" 2>&1

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    echo "💐 Cut successful: $(du -h "$OUTPUT" | cut -f1)"
else
    echo "🍂 Cut failed!"
    exit 1
fi
