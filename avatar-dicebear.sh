#!/bin/bash
# Download random user avatars. in png format.
# This will download 10 avatars on the same current directory

base_url="https://api.dicebear.com/9.x/thumbs/png?radius=0&size=100&shapeColor=c7d2fa&backgroundColor=ffffff&seed="
for i in $(seq 1 10); do
  url="${base_url}user${i}"
  wget -O "user${i}.png" "$url"
  sleep 1
done
