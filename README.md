<div align="center">

<!-- ANIMATED WAVING BANNER - GITHUB FRIENDLY -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=250&section=header&text=YouTube%20Auto%20Upload%20Bot&fontSize=45&fontAlignY=35&desc=by%20Yang%20Mulia%20RICC&descAlignY=55&animation=twinkling" width="100%" alt="banner"/>

<!-- GELOMBANG PELAN PAKE DIVIDER BERGELOMBANG -->
<img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/water.png" width="100%">

</div>

# YouTube Uploader Bot

Auto upload video ke YouTube 2x sehari (06:00 & 19:00 WIB)

## Fitur
- Download dari Google Drive (pake gdown)
- Cut video 60 detik (skip intro 1:16, skip outro 1:53:57)
- AI analisis pake Gemini 2.5 Pro
- Upload ke YouTube
- Tracking progress (112 segmen, 56 hari operasional)
- Notifikasi Telegram (💐 sukses, 🍂 gagal)

## Setup
1. Taruh `token.pickle` dan `client_secret.json` di root folder
2. Set environment variables:
   - `GEMINI_API_KEY`
   - `TELEGRAM_TOKEN`  
   - `TELEGRAM_CHAT_ID`

## GitHub Secrets
- `TOKEN_PICKLE_BASE64` - base64 encoded token.pickle
- `CLIENT_SECRET_BASE64` - base64 encoded client_secret.json
- `GEMINI_API_KEY`
- `TELEGRAM_TOKEN`
- `TELEGRAM_CHAT_ID`

## Progress
Total 112 segmen @ 60 detik = 112 hari (2x/hari = 56 hari operasional)
