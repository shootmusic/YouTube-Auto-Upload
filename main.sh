#!/bin/bash
# YouTube Uploader Main Script

LOG_FILE="./logs/upload_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "🍂 YouTube Uploader Started at $(date)"

# Step 1: Download
log "Step 1/5: Downloading..."
./scripts/download.sh >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Download failed, exiting"
    exit 1
fi

# Step 2: Cut
log "Step 2/5: Cutting video..."
./scripts/cut.sh >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Cut failed, exiting"
    exit 1
fi

# Step 3: AI Analysis
log "Step 3/5: AI analysis with Gemini..."
python3 ./scripts/gemini_analyzer.py >> "$LOG_FILE" 2>&1

# Step 4: Upload
log "Step 4/5: Uploading to YouTube..."
python3 ./scripts/upload.py >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "🍂 Upload failed, exiting"
    exit 1
fi

# Step 5: Cleanup
log "Step 5/5: Cleaning up..."
./scripts/cleanup.sh >> "$LOG_FILE" 2>&1

log "💐 YouTube Uploader Completed at $(date)"
