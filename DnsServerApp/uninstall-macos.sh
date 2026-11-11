#!/bin/sh
#
# Technitium DNS Server - macOS uninstaller
#
#   sudo ./uninstall-macos.sh            # removes the service and program files, keeps config
#   sudo ./uninstall-macos.sh --purge    # also removes config and logs
#

set -e

DNS_DIR="/opt/technitium/dns"
DNS_CONFIG="/etc/dns"
DNS_LOG="/var/log/technitium/dns"
PLIST_NAME="com.technitium.dns"
PLIST_PATH="/Library/LaunchDaemons/$PLIST_NAME.plist"

if [ "$(id -u)" -ne 0 ]
then
    echo "Error: this uninstaller must be run as root."
    echo "  sudo $0"
    exit 1
fi

echo ""
echo "Uninstalling Technitium DNS Server..."

if [ -f "$PLIST_PATH" ]
then
    launchctl bootout system "$PLIST_PATH" 2> /dev/null || true
    rm -f "$PLIST_PATH"
fi

rm -rf "$DNS_DIR"

if [ "$1" = "--purge" ]
then
    rm -rf "$DNS_CONFIG"
    rm -rf "$DNS_LOG"
    echo "Config and logs removed."
else
    echo "Config was kept in $DNS_CONFIG (use --purge to remove it)."
fi

echo "Technitium DNS Server was uninstalled."
echo ""
