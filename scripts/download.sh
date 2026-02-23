#!/bin/bash
# YouTube Uploader - Download with gdown (latest)

VIDEO_ID="1NCYonDGrVwHsSXvN_6gr6GEWWge3HaHy"
OUTPUT_DIR="./temp"
mkdir -p $OUTPUT_DIR

echo "🍂 Downloading video dengan gdown..."

# Install/upgrade gdown dulu
pip install --upgrade gdown

# Download dengan gdown (versi baru otomatis handle confirm)
gdown "https://drive.google.com/uc?id=${VIDEO_ID}" \
      -O "${OUTPUT_DIR}/source.mp4" \
      --fuzzy \
      --remaining-ok

if [ $? -eq 0 ] && [ -f "${OUTPUT_DIR}/source.mp4" ]; then
    filesize=$(stat -c%s "${OUTPUT_DIR}/source.mp4" 2>/dev/null || stat -f%z "${OUTPUT_DIR}/source.mp4" 2>/dev/null)
    
    # Cek apakah file terlalu kecil (kemungkinan HTML error)
    if [ "$filesize" -lt 1000000 ]; then  # < 1MB
        echo "🍂 ERROR: File terlalu kecil (${filesize} bytes) - kemungkinan error"
        echo "🍂 Isi file (5 baris pertama):"
        head -5 "${OUTPUT_DIR}/source.mp4"
        exit 1
    fi
    
    echo "💐 Download successful: $(du -h "${OUTPUT_DIR}/source.mp4" | cut -f1)"
else
    echo "🍂 Download failed!"
    exit 1
fi
