#!/usr/bin/env bash
# Download and save Youtube transcript

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[1;94m"
RESET="\033[0m"

VIDEO_URL="$1"

if [ -z "$VIDEO_URL" ]; then
    echo -e "${RED}Usage: $0 <youtube_url>${RESET}"
    exit 1
fi

if ! echo "$VIDEO_URL" | grep -Eqi '^(https?://)?(www\.)?(youtube\.com|youtu\.be)/'; then
    echo -e "${RED}Error: The provided URL is not a valid YouTube link.${RESET}"
    exit 1
fi

echo -e "${BLUE}Transcript Script${RESET}"

if ! command -v yt-dlp &> /dev/null; then
    echo -e "${RED}yt-dlp not installed. Install it first.${RESET}"
    exit 1
fi

# Get clean title for filename
echo ""
echo -e "${BLUE}Fetching video title...${RESET}"
RAW_TITLE=$(yt-dlp --print "%(title)s" "$VIDEO_URL")
VIDEO_TITLE=$(echo "$RAW_TITLE" | tr ' ' '-' | sed -E 's/[^a-zA-Z0-9-]//g')
echo -e "${GREEN}Clean filename:${RESET} $VIDEO_TITLE"

echo ""
echo -e "${BLUE}Attempting to download subtitles...${RESET}"
# Try manual English
yt-dlp \
    --sub-lang en \
    --convert-subs vtt \
    --write-sub \
    --skip-download \
    --output "subtitle.%(ext)s" \
    "$VIDEO_URL" \
    2>/dev/null
# If not found, try auto English
if ! ls subtitle*.vtt &>/dev/null; then
    echo -e "${YELLOW}Manual EN not available; trying auto EN...${RESET}"
    yt-dlp \
        --sub-lang en \
        --convert-subs vtt \
        --write-auto-sub \
        --skip-download \
        --output "subtitle.%(ext)s" \
        "$VIDEO_URL" \
        2>/dev/null
fi
# If not found, try manual any language
if ! ls subtitle*.vtt &>/dev/null; then
    echo -e "${YELLOW}No EN subtitles; trying manual ANY language...${RESET}"
    yt-dlp \
        --write-sub \
        --convert-subs vtt \
        --skip-download \
        --output "subtitle.%(ext)s" \
        "$VIDEO_URL" \
        2>/dev/null
fi
# If not found, try auto any language
if ! ls subtitle*.vtt &>/dev/null; then
    echo -e "${YELLOW}Trying auto subtitles (ANY language)...${RESET}"
    yt-dlp \
        --write-auto-sub \
        --convert-subs vtt \
        --skip-download \
        --output "subtitle.%(ext)s" \
        "$VIDEO_URL" \
        2>/dev/null
fi

VTT_FILE=$(ls subtitle*.vtt 2>/dev/null | head -n 1)
if [ ! -f "$VTT_FILE" ]; then
    echo -e "${RED}No subtitles exist for this video. Exiting.${RESET}"
    exit 1
fi

echo -e "${GREEN}Subtitle file found:${RESET} $VTT_FILE"

echo ""
echo -e "${BLUE}Converting VTT to TXT...${RESET}"

sed -E '/WEBVTT/d; /-->/d; s/<[^>]*>//g; /^\s*$/d' "$VTT_FILE" \
    | uniq \
    > "${VIDEO_TITLE}.txt"

echo -e "${GREEN}Transcript saved as:${RESET} ${VIDEO_TITLE}.txt"

rm "$VTT_FILE"
echo -e "${GREEN}Temporary subtitle file removed${RESET}"

echo ""
echo -e "${GREEN}Done. Transcript created successfully.${RESET}"
