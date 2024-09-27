#!/bin/bash
chromium-browser http://127.0.0.1:1880/ &
sleep 2  # Optional: wait for a moment to ensure Chromium has launched
xdg-open http://127.0.0.1:1880/ui
