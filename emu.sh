cp ./build/app/outputs/flutter-apk/app-release.apk .

curl -X POST https://api.appetize.io/v1/apps \
  -H "X-API-KEY: ${APPETIZE_API_KEY}" \
  -F "file=@app-release.apk" \
  -F "platform=android"