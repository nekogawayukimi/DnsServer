#!/bin/sh
#
# Technitium DNS Server - macOS build script (Apple Silicon / Intel)
#
# Builds TechnitiumLibrary and publishes DnsServerApp for macOS.
# Run this script from the root of the DnsServer repository.
#
# Usage:
#   ./build-macos.sh                  # framework-dependent build for osx-arm64 (requires ASP.NET Core Runtime to run)
#   ./build-macos.sh --self-contained # standalone build, no .NET runtime needed on the target machine
#   ./build-macos.sh --arch x64       # build for Intel Macs (osx-x64)
#
# Requirements: .NET 10 SDK (https://dotnet.microsoft.com/download/dotnet/10.0)
#   brew install --cask dotnet-sdk    # or use the official installer
#

set -e

ARCH="arm64"
SELF_CONTAINED="false"

while [ $# -gt 0 ]
do
    case "$1" in
        --self-contained)
            SELF_CONTAINED="true"
            ;;
        --arch)
            shift
            ARCH="$1"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--self-contained] [--arch arm64|x64]"
            exit 1
            ;;
    esac
    shift
done

RID="osx-$ARCH"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$PARENT_DIR/TechnitiumLibrary"
PUBLISH_DIR="$SCRIPT_DIR/DnsServerApp/bin/Release/publish-$RID"

if ! command -v dotnet > /dev/null 2>&1
then
    echo "Error: .NET SDK not found. Install it with:"
    echo "  brew install --cask dotnet-sdk"
    echo "or download it from https://dotnet.microsoft.com/download/dotnet/10.0"
    exit 1
fi

echo ""
echo "========================================="
echo "Technitium DNS Server - macOS build ($RID)"
echo "========================================="
echo ""

if [ ! -d "$LIB_DIR" ]
then
    echo "TechnitiumLibrary not found; cloning it next to the DnsServer repository..."
    git clone --depth 1 https://github.com/TechnitiumSoftware/TechnitiumLibrary.git "$LIB_DIR"
fi

echo "Building TechnitiumLibrary..."
dotnet build "$LIB_DIR/TechnitiumLibrary.ByteTree/TechnitiumLibrary.ByteTree.csproj" -c Release
dotnet build "$LIB_DIR/TechnitiumLibrary.Net/TechnitiumLibrary.Net.csproj" -c Release
dotnet build "$LIB_DIR/TechnitiumLibrary.Security.OTP/TechnitiumLibrary.Security.OTP.csproj" -c Release

echo ""
echo "Publishing DnsServerApp for $RID (self-contained: $SELF_CONTAINED)..."
dotnet publish "$SCRIPT_DIR/DnsServerApp/DnsServerApp.csproj" -c Release -r "$RID" --self-contained "$SELF_CONTAINED" -o "$PUBLISH_DIR"

echo ""
echo "Build complete!"
echo ""
echo "Output: $PUBLISH_DIR"
echo ""
echo "To run the DNS server directly:"
echo "  sudo \"$PUBLISH_DIR/DnsServerApp\""
echo ""
echo "To install it as a launchd service (starts at boot):"
echo "  sudo \"$PUBLISH_DIR/install-macos.sh\""
echo ""
echo "Web console: http://localhost:5380/"
echo ""
