@echo off
echo Starting Podcast Studio at http://localhost:8080/podcast-studio.html
echo Press Ctrl+C to stop.
echo.
start http://localhost:8080/podcast-studio.html
python -m http.server 8080 2>nul || python3 -m http.server 8080 2>nul || npx serve -l 8080 . 2>nul || echo Error: Install Python 3 or Node.js
pause
