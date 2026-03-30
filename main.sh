#!/bin/bash
# YouTube Uploader Main Script - Versi Random Cut

mkdir -p ./logs ./temp ./config

LOG_FILE="./logs/upload_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

send_telegram() {
    local msg="$1"
    if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="YouTube Uploader: $msg" > /dev/null 2>&1
    fi
}

PROGRESS="./config/progress.json"
USED_CUTS="./config/used_cuts.txt"

# ── Validasi progress.json ──────────────────────────────────────────
if [ ! -f "$PROGRESS" ]; then
    log "🍂 ERROR: progress.json tidak ditemukan!"
    exit 1
fi

# Validasi field penting (tanpa current_segment)
for field in intro_end outro_start segment_duration total_segments; do
    val=$(jq -r ".${field}" "$PROGRESS")
    if [ "$val" = "null" ] || [ -z "$val" ]; then
        log "🍂 ERROR: Field '$field' kosong di progress.json"
        send_telegram "❌ ERROR: Field '$field' kosong"
        exit 1
    fi
done

# Hitung total segmen yang sudah diupload dari used_cuts.txt
if [ -f "$USED_CUTS" ]; then
    uploaded=$(wc -l < "$USED_CUTS")
else
    uploaded=0
fi

total=$(jq -r '.total_segments' "$PROGRESS")

log "🍂 YouTube Uploader Started at $(date)"
log "📊 Segmen: $uploaded / $total"

# Cek apakah sudah selesai semua
if [ "$uploaded" -ge "$total" ]; then
    log "✅ Semua segmen sudah diupload!"
    send_telegram "✅ Semua $total segmen selesai!"
    exit 0
fi

# ── Step 1: Download ────────────────────────────────────────────────
log "Step 1/5: Downloading from Drive..."
./scripts/download.sh 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Download failed, exiting"
    send_telegram "❌ Download gagal"
    exit 1
fi

# Validasi file hasil download
SOURCE="./temp/source.mp4"
if [ ! -f "$SOURCE" ] || [ ! -s "$SOURCE" ]; then
    log "🍂 ERROR: source.mp4 kosong atau tidak ada"
    send_telegram "❌ source.mp4 tidak valid"
    exit 1
fi

log "✅ Download OK — $(du -h "$SOURCE" | cut -f1)"

# ── Step 2: Cut ─────────────────────────────────────────────────────
log "Step 2/5: Cutting video random 60 detik..."
./scripts/cut.sh 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Cut failed, exiting"
    send_telegram "❌ Cut gagal"
    exit 1
fi

# Validasi output cut
OUTPUT="./temp/segment.mp4"
if [ ! -f "$OUTPUT" ] || [ ! -s "$OUTPUT" ]; then
    log "🍂 ERROR: segment.mp4 kosong setelah cut"
    send_telegram "❌ segment.mp4 tidak valid"
    exit 1
fi

log "✅ Cut OK — $(du -h "$OUTPUT" | cut -f1)"

# ── Step 3: AI Analysis ─────────────────────────────────────────────
log "Step 3/5: AI analysis dengan Gemini (bikin judul unik)..."
python3 ./scripts/gemini_analyzer.py 2>&1 | tee -a "$LOG_FILE"

# ── Step 4: Upload ──────────────────────────────────────────────────
log "Step 4/5: Uploading to YouTube..."
python3 ./scripts/upload.py 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Upload failed, exiting"
    send_telegram "❌ Upload gagal"
    exit 1
fi

log "✅ Upload OK"

# ── Step 5: Cleanup ─────────────────────────────────────────────────
log "Step 5/5: Cleaning up temp files..."
./scripts/cleanup.sh 2>&1 | tee -a "$LOG_FILE"

# ── Hitung ulang progress setelah upload ───────────────────────────
if [ -f "$USED_CUTS" ]; then
    new_uploaded=$(wc -l < "$USED_CUTS")
else
    new_uploaded=$uploaded
fi

remaining=$((total - new_uploaded))
eta=$(( remaining / 2 ))

log "💐 YouTube Uploader Completed at $(date)"
log "📊 Progress: $new_uploaded/$total | Sisa: $remaining video | ETA: $eta hari"
send_telegram "✅ Segmen $new_uploaded/$total berhasil! Sisa: $remaining | ETA: $eta hari"
