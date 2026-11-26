#!/bin/bash
# Run once if macOS says it cannot check for malware.
# Right-click this file → Open → Open, then double-click START.command.
cd "$(dirname "$0")" || exit 1
xattr -cr . 2>/dev/null || true
chmod +x START.command FIX-MAC.command 2>/dev/null || true
osascript -e 'display alert "СИЗО" message "Карантин снят. Теперь двойной клик по START.command."' 2>/dev/null || echo "OK — now double-click START.command"
