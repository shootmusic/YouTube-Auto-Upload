#!/bin/bash
# YouTube Uploader - Download with gdown

VIDEO_ID="14Hir_cMuu8wrxzQh0FqS3oqEQ5a9LKg0"
OUTPUT_DIR="./temp"
mkdir -p $OUTPUT_DIR

echo "🍂 Downloading Big Mouth S1E1 dengan gdown..."

pip install --upgrade gdown > /dev/null 2>&1

gdown "https://drive.google.com/uc?id=${VIDEO_ID}" \
      -O "${OUTPUT_DIR}/source.mp4" \
      --fuzzy \
      --quiet

if [ $? -eq 0 ] && [ -f "${OUTPUT_DIR}/source.mp4" ]; then
    filesize=$(stat -c%s "${OUTPUT_DIR}/source.mp4" 2>/dev/null || stat -f%z "${OUTPUT_DIR}/source.mp4" 2>/dev/null)
    
    if [ "$filesize" -lt 1000000 ]; then
        echo "🍂 ERROR: File terlalu kecil (${filesize} bytes)"
        head -5 "${OUTPUT_DIR}/source.mp4"
        exit 1
    fi
    
    echo "💐 Download successful: $(du -h "${OUTPUT_DIR}/source.mp4" | cut -f1)"
else
    echo "🍂 Download failed!"
    exit 1
fi
