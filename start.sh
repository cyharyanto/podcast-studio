#!/bin/bash
# Launch Podcast Studio on localhost
PORT=8080
echo "Starting Podcast Studio at http://localhost:$PORT/podcast-studio.html"
echo "Press Ctrl+C to stop."
echo ""
python3 -m http.server $PORT 2>/dev/null || python -m http.server $PORT 2>/dev/null || npx serve -l $PORT . 2>/dev/null || echo "Error: Install Python 3 or Node.js"
