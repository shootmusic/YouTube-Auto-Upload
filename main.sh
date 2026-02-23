#!/bin/bash
# YouTube Uploader Main Script

LOG_FILE="./logs/upload_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "🍂 YouTube Uploader Started at $(date)"
log "Total konten: 112 menit 41 detik = 112 segmen + 41 detik sisa"

# Step 1: Download
log "Step 1/5: Downloading from Drive..."
./scripts/download.sh >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Download failed, exiting"
    exit 1
fi

# Step 2: Cut
log "Step 2/5: Cutting video 60 detik..."
./scripts/cut.sh >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Cut failed, exiting"
    exit 1
fi

# Step 3: AI Analysis
log "Step 3/5: AI analysis with Gemini 2.5 Pro..."
python3 ./scripts/gemini_analyzer.py >> "$LOG_FILE" 2>&1

# Step 4: Upload
log "Step 4/5: Uploading to YouTube..."
python3 ./scripts/upload.py >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Upload failed, exiting"
    exit 1
fi

# Step 5: Cleanup
log "Step 5/5: Cleaning up temp files..."
./scripts/cleanup.sh >> "$LOG_FILE" 2>&1

# Baca progress terbaru
current=$(jq -r '.current_segment' ./config/progress.json)
total=$(jq -r '.total_segments' ./config/progress.json)
remaining=$((total - current))

log "💐 YouTube Uploader Completed at $(date)"
log "📊 Progress: $current/$total segmen | Sisa: $remaining video | ETA: $((remaining/2)) hari"
