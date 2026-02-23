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

if [ ! -s "$SOURCE" ]; then
    echo "🍂 ERROR: Source video kosong (0 bytes)"
    exit 1
fi

# ── Baca durasi ─────────────────────────────────────────────────────
duration_raw=$(ffprobe -v error \
    -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 \
    "$SOURCE" 2>/dev/null)

if [ -z "$duration_raw" ]; then
    echo "🍂 ERROR: Tidak bisa membaca durasi video (ffprobe gagal)"
    echo "🍂 Cek apakah file valid:"
    ffprobe -v error -i "$SOURCE" 2>&1 | head -5
    exit 1
fi

duration=$(echo "$duration_raw" | cut -d. -f1)

if [ -z "$duration" ] || [ "$duration" -le 0 ] 2>/dev/null; then
    echo "🍂 ERROR: Durasi tidak valid: '$duration_raw'"
    exit 1
fi

echo "💐 Video duration: ${duration} detik"

# ── Validasi progress.json ──────────────────────────────────────────
if [ ! -f "$PROGRESS" ]; then
    echo "🍂 ERROR: progress.json tidak ditemukan: $PROGRESS"
    exit 1
fi

current=$(jq -r '.current_segment' "$PROGRESS")
intro=$(jq -r '.intro_end' "$PROGRESS")
outro=$(jq -r '.outro_start' "$PROGRESS")
seg_duration=$(jq -r '.segment_duration' "$PROGRESS")

# Validasi semua field tidak null/kosong
for var_name in current intro outro seg_duration; do
    val="${!var_name}"
    if [ "$val" = "null" ] || [ -z "$val" ]; then
        echo "🍂 ERROR: Field '$var_name' null/kosong di progress.json"
        exit 1
    fi
done

echo "📋 Config — current: $current | intro: $intro | outro: $outro | seg_dur: $seg_duration"

# ── Validasi outro ──────────────────────────────────────────────────
if [ "$outro" -ge "$duration" ]; then
    echo "⚠️ outro_start ($outro) >= durasi ($duration), menyesuaikan..."
    outro=$((duration - 60))
    if [ "$outro" -le "$intro" ]; then
        echo "🍂 ERROR: Video terlalu pendek untuk di-cut (durasi: ${duration}s)"
        exit 1
    fi
    echo "⚠️ outro disesuaikan ke: $outro"
    # UPDATE PROGRESS.JSON DENGAN NILAI BARU
    jq --argjson novo "$outro" '.outro_start = $novo' "$PROGRESS" > /tmp/progress_tmp.json && mv /tmp/progress_tmp.json "$PROGRESS"
fi

# ── Hitung start time ───────────────────────────────────────────────
start_time=$((intro + (current * seg_duration)))
max_start=$((outro - seg_duration))

echo "🔢 start_time: $start_time | max_start: $max_start"

if [ "$start_time" -gt "$max_start" ]; then
    echo "⚠️ Start time $start_time melebihi batas ($max_start), reset ke intro"
    start_time=$intro
    jq '.current_segment = 0' "$PROGRESS" > /tmp/progress_tmp.json \
        && mv /tmp/progress_tmp.json "$PROGRESS"
    echo "⚠️ current_segment di-reset ke 0"
fi

# Pastikan start_time tidak melebihi durasi video
if [ "$start_time" -ge "$duration" ]; then
    echo "🍂 ERROR: start_time ($start_time) >= durasi video ($duration)"
    exit 1
fi

# Sesuaikan seg_duration jika mendekati akhir
available=$((duration - start_time))
if [ "$seg_duration" -gt "$available" ]; then
    echo "⚠️ seg_duration ($seg_duration) > sisa video ($available), menyesuaikan..."
    seg_duration=$available
fi

start_formatted=$(printf "%02d:%02d:%02d" \
    $((start_time / 3600)) \
    $(((start_time % 3600) / 60)) \
    $((start_time % 60)))

echo "🍂 Cutting segment $((current + 1)) | Start: $start_formatted | Durasi: ${seg_duration}s"

# ── FFmpeg cut ──────────────────────────────────────────────────────
ffmpeg -y \
    -ss "$start_formatted" \
    -i "$SOURCE" \
    -t "$seg_duration" \
    -c:v libx264 \
    -c:a aac \
    -preset fast \
    -movflags +faststart \
    "$OUTPUT" \
    2>&1

FFMPEG_EXIT=$?

# ── Validasi output ─────────────────────────────────────────────────
if [ $FFMPEG_EXIT -ne 0 ]; then
    echo "🍂 ERROR: ffmpeg keluar dengan kode $FFMPEG_EXIT"
    exit 1
fi

if [ ! -f "$OUTPUT" ] || [ ! -s "$OUTPUT" ]; then
    echo "🍂 ERROR: Output file kosong atau tidak ada: $OUTPUT"
    exit 1
fi

# Verifikasi output bisa dibaca
ffprobe -v error -i "$OUTPUT" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "🍂 ERROR: Output file corrupt"
    exit 1
fi

out_size=$(du -h "$OUTPUT" | cut -f1)
out_dur=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$OUTPUT" 2>/dev/null | cut -d. -f1)

echo "💐 Cut successful: ${out_size} | Durasi output: ${out_dur}s"
