
curl -X POST "https://api.appetize.io/v1/apps/b_xmb2plwjnp2gladundg4jme3pi" \
  -H "X-API-KEY: ${APPETIZE_API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: */*" \
  -d '{
    "url": "https://zany-fishstick-pw6rx466jx62jpv-80.app.github.dev/app-release.apk",
    "platform": "android",
    "fileType": "apk",
    "timeout": 120,
    "timeLimit": 200,
    "maxConcurrent": 5,

    "disabled": false,
    "disableHome": false,
    "useLastFrame": false,
    "buttonText": "Start",
    "postSessionButtonText": "Restart",
    "appPermissions": {
      "run": "authenticated",
      "networkProxy": "public",
      "networkIntercept": "public",
      "debugLog": "public",
      "adbConnect": "public",
      "androidPackageManager": "public"
    }
  }'
 
