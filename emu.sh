cp ./build/app/outputs/flutter-apk/app-release.apk .

curl -X POST https://api.appetize.io/v1/apps/b_xmb2plwjnp2gladundg4jme3pi \
  -H "X-API-KEY: ${APPETIZE_API_KEY}" \
  -F "file=@app-release.apk" \
  -F "platform=android"