#!/bin/bash
# YouTube Uploader Main Script - Versi used_cuts

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

# Baca total segmen
total=$(jq -r '.total_segments' "$PROGRESS")

# Hitung uploaded dari used_cuts.txt
if [ -f "$USED_CUTS" ]; then
    uploaded=$(wc -l < "$USED_CUTS")
else
    uploaded=0
fi

log "🍂 YouTube Uploader Started at $(date)"
log "📊 Progress: $uploaded / $total"

# Cek selesai
if [ "$uploaded" -ge "$total" ]; then
    log "✅ Semua segmen selesai!"
    send_telegram "✅ Semua $total segmen selesai!"
    exit 0
fi

# Step 1: Download
log "Step 1/5: Downloading..."
./scripts/download.sh 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Download failed"
    exit 1
fi

# Step 2: Cut (otomatis nambah ke used_cuts.txt)
log "Step 2/5: Cutting random..."
./scripts/cut.sh 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Cut failed"
    exit 1
fi

# Step 3: AI Analysis
log "Step 3/5: AI analysis..."
python3 ./scripts/gemini_analyzer.py 2>&1 | tee -a "$LOG_FILE"

# Step 4: Upload
log "Step 4/5: Uploading..."
python3 ./scripts/upload.py 2>&1 | tee -a "$LOG_FILE"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "🍂 Upload failed"
    exit 1
fi

# Step 5: Cleanup
log "Step 5/5: Cleanup..."
./scripts/cleanup.sh 2>&1 | tee -a "$LOG_FILE"

# Hitung ulang progress setelah upload
if [ -f "$USED_CUTS" ]; then
    new_uploaded=$(wc -l < "$USED_CUTS")
else
    new_uploaded=$uploaded
fi

remaining=$((total - new_uploaded))
eta=$(( remaining / 2 ))

log "💐 Completed at $(date)"
log "📊 Progress: $new_uploaded/$total | Sisa: $remaining | ETA: $eta hari"
send_telegram "🎉 Segmen $new_uploaded/$total berhasil! Sisa: $remaining | ETA: $eta hari"
