#!/bin/bash
# WSL ADB Bridge Script
# This script helps connect WSL Flutter to Windows ADB server

# Get Windows host IP
WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Path to Windows ADB
WIN_ADB="/mnt/c/Users/$USER/AppData/Local/Android/Sdk/platform-tools/adb.exe"

echo "Windows Host IP: $WINDOWS_HOST"
echo "Starting ADB server on Windows..."

# Kill any existing ADB server
$WIN_ADB kill-server 2>/dev/null

# Start ADB server on Windows
$WIN_ADB start-server

# Check connected devices
echo "Connected devices:"
$WIN_ADB devices

echo ""
echo "To run your Flutter app, use:"
echo "  cd /home/cmwen/dev/private-chat-hub"
echo "  flutter run"
echo ""
echo "Note: If Flutter still doesn't detect the device, run Flutter from Windows instead."
