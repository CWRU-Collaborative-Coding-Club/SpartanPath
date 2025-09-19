#!/bin/sh

set -e

cp ./build/app/outputs/flutter-apk/app-release.apk ./public
cd ./public
python3 -m http.server 80 


