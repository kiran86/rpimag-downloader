#!/bin/bash
set -e

# Defaults
DOWNLOAD_DIR="./MagPi_Issues"
MODE="all"
RANGE=""
LATEST=""

usage() {
  echo "Usage: $0 [-o output_dir] [-a | -c | -r start-end]"
  echo
  echo "Options:"
  echo "  -o <dir>      Output directory (default: ./MagPi_Issues)"
  echo "  -a            Download all issues (1 → latest-1) [default]"
  echo "  -c            Download current issue only (latest-1)"
  echo "  -r s-e        Download a range of issues (e.g. -r 50-60)"
  exit 1
}

# Show usage if no arguments are provided
if [ $# -eq 0 ]; then
  usage
fi

# Parse args
while getopts ":o:acr:" opt; do
  case $opt in
    o) DOWNLOAD_DIR="$OPTARG" ;;
    a) MODE="all" ;;
    c) MODE="current" ;;
    r) MODE="range"; RANGE="$OPTARG" ;;
    *) usage ;;
  esac
done

mkdir -p "$DOWNLOAD_DIR"

# Get latest issue number
LATEST=$(curl -s "https://magazine.raspberrypi.com/issues" \
  | grep -oE '/issues/[0-9]+' \
  | awk -F/ '{print $3}' \
  | sort -n | tail -1)

END=$((LATEST - 1))

# Decide which issues to download
case "$MODE" in
  all)
    START=1
    ;;
  current)
    START=$END
    ;;
  range)
    START=$(echo "$RANGE" | cut -d- -f1)
    END=$(echo "$RANGE" | cut -d- -f2)
    ;;
esac

echo "Latest issue online: $LATEST"
echo "Downloading issues $START → $END into $DOWNLOAD_DIR"

# Main loop
for issue in $(seq $START $END); do
    outfile="$DOWNLOAD_DIR/MagPi$(printf "%03d" $issue).pdf"
    if [[ -f "$outfile" ]]; then
        echo "[$issue] already exists, skipping."
        continue
    fi

    echo -n "[$issue] extracting link... "
    pdf_url=$(node get_pdf_url.js $issue)

    if [[ -n "$pdf_url" ]]; then
        echo "found, downloading..."
        curl -L --progress-bar -C - -o "$outfile" "$pdf_url"
    else
        echo "no PDF link found."
    fi
done
