#!/bin/sh
#
# Technitium DNS Server - macOS installer (launchd service)
#
# Installs the published DNS server into /opt/technitium/dns and registers
# it as a launchd daemon so it starts automatically at boot.
#
# Run this script from the publish output folder (it is copied there by
# the build), after building with ./build-macos.sh:
#   sudo ./install-macos.sh
#

set -e

DNS_DIR="/opt/technitium/dns"
DNS_CONFIG="/etc/dns"
DNS_LOG="/var/log/technitium/dns"
PLIST_NAME="com.technitium.dns"
PLIST_PATH="/Library/LaunchDaemons/$PLIST_NAME.plist"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "========================================="
echo "Technitium DNS Server Installer for macOS"
echo "========================================="
echo ""

if [ "$(id -u)" -ne 0 ]
then
    echo "Error: this installer must be run as root."
    echo "  sudo $0"
    exit 1
fi

if [ "$(uname -s)" != "Darwin" ]
then
    echo "Error: this installer is for macOS only. Use install.sh on Linux."
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/DnsServerApp.dll" ]
then
    echo "Error: DnsServerApp.dll not found next to this script."
    echo "Build the server first with ./build-macos.sh and run the installer"
    echo "from the publish output folder."
    exit 1
fi

# If the binary is framework-dependent, make sure a .NET runtime is available.
if [ ! -f "$SCRIPT_DIR/System.Private.CoreLib.dll" ] && ! command -v dotnet > /dev/null 2>&1 && [ ! -x "/usr/local/share/dotnet/dotnet" ]
then
    echo "Error: this is a framework-dependent build but no .NET runtime was found."
    echo "Install the ASP.NET Core Runtime from https://dotnet.microsoft.com/download/dotnet/10.0"
    echo "or rebuild with: ./build-macos.sh --self-contained"
    exit 1
fi

# Stop an existing service before replacing files.
if [ -f "$PLIST_PATH" ]
then
    echo "Stopping existing DNS service..."
    launchctl bootout system "$PLIST_PATH" 2> /dev/null || true
fi

echo "Installing Technitium DNS Server into $DNS_DIR..."
mkdir -p "$DNS_DIR"
mkdir -p "$DNS_CONFIG"
mkdir -p "$DNS_LOG"

# Copy the published output (this script's folder) into the install dir.
# rsync-like copy with cp; --delete semantics are not needed for upgrades.
cp -Rf "$SCRIPT_DIR/." "$DNS_DIR/"
chmod +x "$DNS_DIR/DnsServerApp" 2> /dev/null || true

echo "Registering launchd service..."
cp -f "$DNS_DIR/$PLIST_NAME.plist" "$PLIST_PATH"
chown root:wheel "$PLIST_PATH"
chmod 644 "$PLIST_PATH"

launchctl bootstrap system "$PLIST_PATH"
launchctl kickstart -k "system/$PLIST_NAME" 2> /dev/null || true

echo ""
echo "Technitium DNS Server was installed successfully!"
echo ""
echo "Web console:   http://localhost:5380/"
echo "Config folder: $DNS_CONFIG"
echo "Logs:          $DNS_LOG"
echo ""
echo "Manage the service with:"
echo "  sudo launchctl kickstart -k system/$PLIST_NAME   # (re)start"
echo "  sudo launchctl bootout system $PLIST_PATH        # stop"
echo "  sudo launchctl bootstrap system $PLIST_PATH      # start"
echo ""
echo "Note: macOS may already use port 53 (e.g. Internet Sharing) or port 5380."
echo "Check with: sudo lsof -nP -iUDP:53 -iTCP:5380"
echo ""
